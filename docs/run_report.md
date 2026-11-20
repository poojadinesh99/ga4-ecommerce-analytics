## Pipeline run

- dbt version: `1.12.7`
- generated at: `2026-11-20T15:18:28.244952Z`
- command: `build`
- total elapsed: 78s

| Resource | Status | Count |
|---|---|---|
| exposure | no-op | 1 |
| model | success | 10 |
| test | pass | 66 |

### Row counts

| Table | Rows |
|---|---|
| stg_ga4__event_items | view |
| stg_ga4__events | view |
| int_ga4__purchases | 5,692 |
| fct_item_performance | 1,393 |
| int_ga4__sessions | 360,129 |
| fct_sessions | 360,129 |
| fct_funnel_daily | 1,956 |
| fct_orders | 4,466 |
| fct_conversion_by_channel | 10 |
| fct_funnel_steps | 9,780 |
