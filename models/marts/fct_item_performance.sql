{#-
  Product-level funnel and sales, one row per item_id.
  Engagement (views, carts, checkouts) counts distinct sessions, so repeated events in a
  session count once. Sales (orders, units, revenue) use only item lines of counted
  purchases (int_ga4__purchases), so duplicate purchase events and purchases without a
  transaction_id are not counted. Each (purchase_event_key, item_index) line counts once,
  which also drops byte-identical duplicate rows of the counted event.
  item_revenue_usd is GA4's item_revenue_in_usd (price x quantity). It is not expected to
  sum to order revenue, which can include tax and shipping.
-#}
with items as (

    select * from {{ ref('stg_ga4__event_items') }}

),

counted_purchase_items as (

    select items.*, counted.order_key
    from items
    inner join (
        select distinct purchase_event_key, order_key
        from {{ ref('int_ga4__purchases') }}
        where purchase_status = 'counted'
    ) as counted
        using (purchase_event_key)
    where items.event_name = 'purchase'
    qualify row_number() over (partition by purchase_event_key, item_index order by event_ts) = 1

),

engagement as (

    select
        item_id,
        count(distinct if(event_name = 'view_item', session_key, null))      as view_item_sessions,
        count(distinct if(event_name = 'add_to_cart', session_key, null))    as add_to_cart_sessions,
        count(distinct if(event_name = 'begin_checkout', session_key, null)) as begin_checkout_sessions
    from items
    where event_name != 'purchase'
    group by item_id

),

sales as (

    select
        item_id,
        count(distinct order_key)      as orders,
        sum(quantity)                  as units_sold,
        sum(item_revenue_usd)          as item_revenue_usd
    from counted_purchase_items
    group by item_id

),

item_names as (

    select
        item_id,
        any_value(item_name)     as item_name,
        any_value(item_category) as item_category
    from items
    group by item_id

)

select
    item_names.item_id,
    item_names.item_name,
    item_names.item_category,
    coalesce(engagement.view_item_sessions, 0)      as view_item_sessions,
    coalesce(engagement.add_to_cart_sessions, 0)    as add_to_cart_sessions,
    coalesce(engagement.begin_checkout_sessions, 0) as begin_checkout_sessions,
    coalesce(sales.orders, 0)                       as orders,
    coalesce(sales.units_sold, 0)                   as units_sold,
    coalesce(sales.item_revenue_usd, 0)             as item_revenue_usd,
    safe_divide(engagement.add_to_cart_sessions, engagement.view_item_sessions) as view_to_cart_rate
from item_names
left join engagement using (item_id)
left join sales using (item_id)
