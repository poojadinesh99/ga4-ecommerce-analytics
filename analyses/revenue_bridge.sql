-- 1. Bridge from raw GA4 purchase rows to counted orders.
--    Every dollar of raw purchase revenue falls into exactly one row here.
select
    purchase_status,
    session_key is not null          as has_session,
    count(*)                         as purchase_rows,
    count(distinct order_key)        as distinct_orders,
    countif(revenue_usd is null)     as rows_without_revenue,
    sum(revenue_usd)                 as revenue_usd,
    round(safe_divide(sum(revenue_usd), sum(sum(revenue_usd)) over ()), 4) as share_of_raw_revenue
from {{ ref('int_ga4__purchases') }}
group by 1, 2
order by 1, 2;

-- 2. Order revenue vs item revenue for counted orders. They are different definitions
--    (order revenue can include tax and shipping; item revenue is price x quantity),
--    so a gap is expected. This query measures it; nothing assumes it is zero.
with item_totals as (
    select order_key, sum(item_revenue_usd) as item_revenue_usd
    from (
        select items.*, p.order_key
        from {{ ref('stg_ga4__event_items') }} as items
        inner join {{ ref('int_ga4__purchases') }} as p using (purchase_event_key)
        where p.purchase_status = 'counted'
        qualify row_number() over (partition by items.purchase_event_key, items.item_index order by items.event_ts) = 1
    )
    group by order_key
)
select
    count(*)                                              as orders,
    sum(orders.revenue_usd)                               as order_revenue_usd,
    sum(item_totals.item_revenue_usd)                     as item_revenue_usd,
    countif(orders.revenue_usd = item_totals.item_revenue_usd) as orders_matching_exactly,
    countif(item_totals.order_key is null)           as orders_without_items
from {{ ref('fct_orders') }} as orders
left join item_totals using (order_key);
