-- Item sales must not double count: the sum of per-item order counts must equal the
-- number of distinct (item, counted order) pairs, computed independently here.
with item_orders as (
    select sum(orders) as item_order_pairs from {{ ref('fct_item_performance') }}
),
counted_lines as (
    select count(*) as pairs
    from (
        select distinct items.item_id, purchases.order_key
        from {{ ref('stg_ga4__event_items') }} as items
        inner join {{ ref('int_ga4__purchases') }} as purchases
            using (purchase_event_key)
        where purchases.purchase_status = 'counted'
    )
)
select item_orders.item_order_pairs, counted_lines.pairs
from item_orders, counted_lines
where item_orders.item_order_pairs != counted_lines.pairs
