# GA4 E-commerce Funnel Analytics (BigQuery + dbt + Tableau)

End-to-end analytics on Google's public **GA4 sample export for the Google
Merchandise Store** (`bigquery-public-data.ga4_obfuscated_sample_ecommerce`,
Nov 2020 to Jan 2021, ~4M events).

**Stack:** BigQuery (sandbox) · dbt (BigQuery adapter + dbt_utils) · Tableau Public

**Questions it answers**
- Where do sessions drop out of the funnel: view item → add to cart → checkout → purchase?
- Which acquisition channels convert, and which bring traffic but no revenue?
- How do device type and new vs returning users change conversion?
- Which products get viewed but not added to cart?

## Lineage

```
source: ga4.events_*  (date-sharded GA4 export)
  ├── stg_ga4__events          event grain, event_params flattened, session_key
  │     └── int_ga4__sessions  session grain: source/medium, landing page, funnel events
  │           └── fct_sessions             + channel grouping, funnel depth, reached_* flags
  │                 ├── fct_funnel_daily          date × channel × device (wide)
  │                 │     └── fct_funnel_steps    same, long format for Tableau
  │                 ├── fct_conversion_by_channel channel scorecard
  │                 └── fct_orders                one row per transaction
  └── stg_ga4__event_items     item grain (unnested items array)
        └── fct_item_performance  product funnel
```

## Modeling decisions

- **Session key** = `md5(user_pseudo_id || ga_session_id)`. `ga_session_id` on its
  own is a timestamp and is not unique across users.
- **Session channel** uses the session-scoped `source`/`medium` event params (first
  non-null value in the session), not `traffic_source`, which is the user's
  *first-touch* acquisition and does not change between sessions. Both are kept.
- **Channel grouping** is a simplified version of GA4's default channel group
  (`macros/channel_group.sql`). The sample is obfuscated, with values such as
  `<Other>` and `(data deleted)`. These go to an explicit
  `Unattributed (obfuscated)` bucket so they are not counted as Direct.
- **Funnel flags are cumulative.** A session that purchased counts as having reached
  checkout even if `begin_checkout` was not logged. This keeps the funnel monotonic,
  and a singular test checks it. Raw `has_*` flags are kept alongside.
- **Orders are deduplicated** on `transaction_id`, because GA4 can send a purchase more than once.
- **Sandbox-friendly:** only views and `CREATE OR REPLACE` tables, with no
  incremental/MERGE (the sandbox does not support DML). The date window is a var
  so dev runs scan less data.

## Data quality (dbt tests)

| Kind | What |
|------|------|
| Generic | `unique` / `not_null` on every grain key (session, transaction, item, channel) |
| Generic | `accepted_values` on channel group, device, funnel step |
| dbt_utils | `unique_combination_of_columns` on the funnel tables' grain; `accepted_range` keeps rates in [0, 1] and revenue, durations and engagement ≥ 0 |
| Relationships | every order's session exists in `fct_sessions` (warn) |
| Singular | `assert_funnel_is_monotonic`: each step ≤ previous step, for every date/channel/device |
| Singular | `assert_sessions_preserved_in_funnel`: session totals match across all three funnel models |
| Singular | `assert_order_revenue_reconciles`: order revenue is within 2% of session revenue (warn) |

## Run it

### 1. BigQuery sandbox (free, no credit card)
1. Go to <https://console.cloud.google.com/bigquery>, sign in, and create a project.
   The sandbox is enabled automatically.
2. Note the project ID. The public dataset is in the **US** multi-region, so your
   dbt datasets must be in `US` too (the profile below sets this).
3. Sandbox limits: 1 TB of queries and 10 GB of storage per month, and tables
   expire after 60 days. A full build of this project scans a few GB.

### 2. dbt
```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
gcloud auth application-default login        # install the gcloud CLI first
cp profiles.yml.example profiles.yml         # then set `project:`
dbt deps
dbt debug
dbt build                                    # runs models + tests in DAG order
# faster dev loop on one week of data:
dbt build --vars '{ga4_start_date: "20201201", ga4_end_date: "20201207"}'
dbt docs generate && dbt docs serve          # lineage graph + column docs
```

### 3. Tableau Public
```bash
python scripts/export_marts.py --project YOUR_GCP_PROJECT_ID
```
Then build the dashboard by following [docs/tableau_dashboard.md](docs/tableau_dashboard.md).
Tableau Public cannot connect to BigQuery directly, so the dashboard uses CSV extracts.

**Dashboard:** _add your Tableau Public link here_

### 4. Optional
Google Analytics Certification on Skillshop (free, ~4–5 h).

## Caveats

This is an obfuscated sample. Some source/medium values are redacted, some
`transaction_id`s are `(not set)`, and revenue is not real. The numbers show the
method and should not be read as findings about the real store.
