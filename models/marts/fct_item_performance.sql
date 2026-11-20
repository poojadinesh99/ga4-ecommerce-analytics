{#- Product-level funnel: how often each item is viewed, carted, checked out and bought. -#}
select
    item_id,
    any_value(item_name)                                         as item_name,
    any_value(item_category)                                     as item_category,
    count(distinct if(event_name = 'view_item', session_key, null))      as view_item_sessions,
    count(distinct if(event_name = 'add_to_cart', session_key, null))    as add_to_cart_sessions,
    count(distinct if(event_name = 'begin_checkout', session_key, null)) as begin_checkout_sessions,
    count(distinct if(event_name = 'purchase', transaction_id, null))    as orders,
    sum(if(event_name = 'purchase', quantity, 0))                        as units_sold,
    sum(if(event_name = 'purchase', item_revenue_in_usd, 0))             as item_revenue_usd,
    safe_divide(
        count(distinct if(event_name = 'add_to_cart', session_key, null)),
        count(distinct if(event_name = 'view_item', session_key, null))
    )                                                                    as view_to_cart_rate
from {{ ref('stg_ga4__event_items') }}
group by item_id
