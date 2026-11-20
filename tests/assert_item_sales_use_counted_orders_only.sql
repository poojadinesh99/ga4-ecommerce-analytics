-- Item sales must not double count: every order counted for an item must be a real
-- counted order, and the number of (item, order) pairs cannot exceed what fct_orders
-- supports. Fails if item order counts exceed the counted purchase lines available.
with item_orders as (
    select sum(orders) as item_order_pairs from {{ ref('fct_item_performance') }}
),
counted_lines as (
    -- distinct (item_id, transaction_id) pairs among counted purchases
    select count(*) as pairs
    from (
        select distinct items.item_id, items.transaction_id
        from {{ ref('stg_ga4__event_items') }} as items
        inner join {{ ref('int_ga4__purchases') }} as purchases
            using (purchase_event_key)
        where purchases.purchase_status = 'counted'
    )
)
select item_orders.item_order_pairs, counted_lines.pairs
from item_orders, counted_lines
where item_orders.item_order_pairs != counted_lines.pairs
