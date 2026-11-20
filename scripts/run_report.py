"""Turn the last `dbt build` into a Markdown evidence report for the README.

Reads target/run_results.json (written by dbt) and, if --project is given, the row
counts of the built tables from BigQuery metadata (free, no query cost).

Usage:
    dbt build
    python scripts/run_report.py --project YOUR_GCP_PROJECT_ID > docs/run_report.md
"""
import argparse
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", help="GCP project with the dbt output (enables row counts)")
    parser.add_argument("--dataset-prefix", default="ga4_dbt")
    args = parser.parse_args()

    results = json.loads((ROOT / "target" / "run_results.json").read_text())
    meta = results["metadata"]
    rows = results["results"]

    def kind(r):
        return r["unique_id"].split(".")[0]

    print("## Pipeline run\n")
    print(f"- dbt version: `{meta['dbt_version']}`")
    print(f"- generated at: `{meta['generated_at']}`")
    print(f"- command: `{results['args'].get('which', 'build')}`")
    print(f"- total elapsed: {results['elapsed_time']:.0f}s\n")

    counts = Counter((kind(r), r["status"]) for r in rows)
    print("| Resource | Status | Count |\n|---|---|---|")
    for (k, status), n in sorted(counts.items()):
        print(f"| {k} | {status} | {n} |")

    problems = [r for r in rows if r["status"] not in ("success", "pass", "no-op")]
    if problems:
        print("\n### Warnings and failures\n")
        print("| Node | Status | Failing rows | Message |\n|---|---|---|---|")
        for r in problems:
            msg = (r.get("message") or "").replace("\n", " ")[:160]
            print(f"| `{r['unique_id'].split('.')[-1]}` | {r['status']} | {r.get('failures') or ''} | {msg} |")
        print("\n_Explain each item above before publishing._")

    if args.project:
        from google.cloud import bigquery

        client = bigquery.Client(project=args.project)
        print("\n### Row counts\n")
        print("| Table | Rows |\n|---|---|")
        for r in rows:
            if kind(r) != "model" or r["status"] != "success":
                continue
            name = r["unique_id"].split(".")[-1]
            layer = "staging" if name.startswith("stg_") else "intermediate" if name.startswith("int_") else "marts"
            table = client.get_table(f"{args.project}.{args.dataset_prefix}_{layer}.{name}")
            n = table.num_rows if table.table_type == "TABLE" else "view"
            print(f"| {name} | {n:,} |" if isinstance(n, int) else f"| {name} | {n} |")


if __name__ == "__main__":
    main()
