{#-
  One row per transaction: the counted purchase event for each transaction_id.
  Orders whose purchase event had no ga_session_id have session_key = NULL and NULL
  session attributes (channel, device, ...). has_session marks them.
  revenue_usd is GA4's purchase_revenue_in_usd in NUMERIC cents, NULL if GA4 sent none.
-#}
select
    purchases.transaction_id,
    purchases.event_ts               as ordered_at,
    purchases.event_date             as order_date,
    purchases.user_pseudo_id,
    purchases.session_key,
    purchases.session_key is not null as has_session,
    sessions.channel_group,
    sessions.device_category,
    sessions.country,
    sessions.user_type,
    purchases.total_item_quantity,
    purchases.revenue_usd
from {{ ref('int_ga4__purchases') }} as purchases
left join {{ ref('fct_sessions') }} as sessions
    on purchases.session_key = sessions.session_key
where purchases.purchase_status = 'counted'
