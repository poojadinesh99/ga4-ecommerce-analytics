{#- One row per transaction. GA4 can log the same purchase more than once, so keep the first. -#}
with purchases as (

    select *
    from {{ ref('stg_ga4__events') }}
    where event_name = 'purchase'
      and transaction_id is not null
    qualify row_number() over (partition by transaction_id order by event_ts) = 1

)

select
    purchases.transaction_id,
    purchases.event_ts               as ordered_at,
    purchases.event_date             as order_date,
    purchases.user_pseudo_id,
    purchases.session_key,
    sessions.channel_group,
    sessions.device_category,
    sessions.country,
    sessions.is_new_user,
    purchases.total_item_quantity,
    coalesce(purchases.purchase_revenue_usd, 0) as revenue_usd
from purchases
left join {{ ref('fct_sessions') }} as sessions
    on purchases.session_key = sessions.session_key
