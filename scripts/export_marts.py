"""Export the dbt mart tables to CSV for Tableau Public.

Tableau Public cannot connect to BigQuery, so the dashboard reads CSV extracts.

Usage:
    gcloud auth application-default login
    python scripts/export_marts.py --project YOUR_GCP_PROJECT_ID [--dataset ga4_dbt_marts]
"""
import argparse
import csv
from pathlib import Path

from google.cloud import bigquery

TABLES = [
    "fct_funnel_steps",
    "fct_funnel_daily",
    "fct_conversion_by_channel",
    "fct_orders",
    "fct_item_performance",
]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", required=True, help="GCP project that holds the dbt output")
    parser.add_argument("--dataset", default="ga4_dbt_marts", help="dataset with the mart tables")
    parser.add_argument("--out", default=str(Path(__file__).resolve().parents[1] / "exports"))
    args = parser.parse_args()

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    client = bigquery.Client(project=args.project)

    for name in TABLES:
        table = client.get_table(f"{args.project}.{args.dataset}.{name}")
        path = out_dir / f"{name}.csv"
        with path.open("w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow([field.name for field in table.schema])
            rows = 0
            for row in client.list_rows(table):  # list_rows reads storage, no query cost
                writer.writerow(list(row.values()))
                rows += 1
        print(f"{name}: {rows:,} rows -> {path}")


if __name__ == "__main__":
    main()
