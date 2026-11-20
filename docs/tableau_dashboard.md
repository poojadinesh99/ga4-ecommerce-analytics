# Tableau Public dashboard: build guide

Four sections, readable in under two minutes: **conversion funnel**, **acquisition
channels**, **device segmentation**, **product engagement**.

Data: the CSVs written by `scripts/export_marts.py` into `exports/`.
In Tableau Public, connect to `fct_funnel_steps.csv`, then add the other CSVs as
separate data sources (they are at different grains, so do not join them).

## Sheets

| # | Sheet | Source | Build |
|---|-------|--------|-------|
| 1 | KPI tiles | fct_conversion_by_channel | SUM(sessions), SUM(transactions), SUM(purchase_revenue_usd), and the calcs below as text tiles |
| 2 | Funnel | fct_funnel_steps | Rows: `step_name` (sort by `step_order`); Columns: SUM(sessions_inferred); label with `% of first step` |
| 3 | Observed vs inferred | fct_funnel_steps | Side-by-side bars of SUM(sessions_observed) and SUM(sessions_inferred) per step. The gap shows how many sessions skipped logging a step |
| 3b | Step drop-off | fct_funnel_steps | Bar of `% of previous step` by step_name, colored by drop-off |
| 4 | Conversion by channel | fct_conversion_by_channel | Bar: channel_group × session conversion rate; size or tooltip = sessions |
| 5 | Channel matrix | fct_conversion_by_channel | Scatter: share_of_sessions (x) vs share_of_revenue (y), one mark per channel |
| 6 | Daily trend | fct_funnel_daily | Line: session_date × sessions and conversion rate (dual axis) |
| 6b | Device split | fct_funnel_daily | Conversion rate and revenue by device_category |
| 7 | Top products | fct_item_performance | Top 15 by item_revenue_usd, with view_to_cart_rate as color |

Filters (apply to all sheets using fct_funnel_steps / fct_funnel_daily):
`channel_group`, `device_category`, `session_date` range.

## Calculated fields

Recompute rates from counts in Tableau. Do not average the precomputed rate
columns, because averaging rates across channels gives the wrong answer.

```
// fct_funnel_steps
% of first step     = SUM([sessions_inferred]) / WINDOW_MAX(SUM([sessions_inferred]))           // table calc along step_name
% of previous step  = SUM([sessions_inferred]) / LOOKUP(SUM([sessions_inferred]), -1)

// fct_conversion_by_channel / fct_funnel_daily
Conversion rate     = SUM([purchase_sessions]) / SUM([sessions])             // on fct_funnel_daily: purchase_sessions_inferred
AOV                 = SUM([purchase_revenue_usd]) / SUM([transactions])
Revenue / session   = SUM([purchase_revenue_usd]) / SUM([sessions])
```

## Publish

File → Save to Tableau Public. Copy the public URL into
`models/marts/_exposures.yml` (`url:`) and the README.
