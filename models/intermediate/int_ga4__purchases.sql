{#-
  One row per GA4 purchase event row, flagged with whether it counts as an order.

  Order identity is (transaction_id, user_pseudo_id), not transaction_id alone. On the
  real data, every transaction_id repeated by the same user repeats the same revenue on
  the same day (true duplicates), while ids shared by different users carry different
  revenue on different dates (collisions in the obfuscated sample, i.e. different orders).

  For each order_key exactly one row is 'counted': the earliest, with purchase_event_key
  as a deterministic tie-break. Not counted:
    duplicate               later rows of the same order, incl. byte-identical copies
    missing_transaction_id  null / '' / '(not set)' / '<Other>', cannot be deduplicated
  fct_orders, session revenue and item sales all read the counted rows.
  revenue_usd stays NULL when GA4 sent no revenue, so it is not silently counted as 0.
-#}
with purchases as (

    select
        purchase_event_key,
        case
            when transaction_id is not null
            then to_hex(sha256(to_json_string(struct(transaction_id, user_pseudo_id))))
        end                  as order_key,
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
        when order_key is null then 'missing_transaction_id'
        when row_number() over (
            partition by order_key
            order by event_ts, purchase_event_key
        ) = 1 then 'counted'
        else 'duplicate'
    end as purchase_status
from purchases
