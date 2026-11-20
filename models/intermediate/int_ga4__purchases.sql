{#-
  One row per GA4 purchase event row, flagged with whether it counts as an order.
  For each transaction_id exactly one row is 'counted': the earliest, with
  purchase_event_key as a deterministic tie-break. Not counted:
    duplicate               later rows repeating a counted transaction_id, including
                            byte-identical copies of the counted row
    missing_transaction_id  null / '' / '(not set)' / '<Other>', cannot be deduplicated
  fct_orders, session revenue and item sales all read the counted rows.
  revenue_usd stays NULL when GA4 sent no revenue, so it is not silently counted as 0.
-#}
with purchases as (

    select
        purchase_event_key,
        session_key,
        user_pseudo_id,
        event_ts,
        event_date,
        transaction_id,
        purchase_revenue_usd as revenue_usd,
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
            order by event_ts, purchase_event_key
        ) = 1 then 'counted'
        else 'duplicate'
    end as purchase_status
from purchases
