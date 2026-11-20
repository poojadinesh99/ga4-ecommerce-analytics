{#-
  One row per GA4 purchase event, flagged with whether it counts as an order.
  A purchase event counts once per transaction_id (the earliest event wins).
  Not counted:
    - duplicates: later events repeating a transaction_id already seen
    - events with no transaction_id (null or '(not set)'), which cannot be deduplicated
  Both fct_orders and session revenue read the counted rows, so they always agree.
-#}
with purchases as (

    select
        session_key,
        user_pseudo_id,
        event_ts,
        event_date,
        transaction_id,
        coalesce(purchase_revenue_usd, 0) as revenue_usd,
        total_item_quantity
    from {{ ref('stg_ga4__events') }}
    where event_name = 'purchase'

)

select
    *,
    case
        when transaction_id is null then 'missing_transaction_id'
        when row_number() over (
            partition by transaction_id
            order by event_ts, session_key, revenue_usd desc
        ) = 1 then 'counted'
        else 'duplicate'
    end as purchase_status
from purchases
