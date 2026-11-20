{#- One row per transaction: the counted purchase event for each transaction_id. -#}
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
    purchases.revenue_usd
from {{ ref('int_ga4__purchases') }} as purchases
left join {{ ref('fct_sessions') }} as sessions
    on purchases.session_key = sessions.session_key
where purchases.purchase_status = 'counted'
