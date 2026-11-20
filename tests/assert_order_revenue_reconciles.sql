-- Revenue from deduplicated orders should be within 2% of session-level purchase revenue.
-- A bigger gap means duplicate purchase events or sessionisation problems.
{{ config(severity = 'warn') }}

with orders as (
    select sum(revenue_usd) as revenue from {{ ref('fct_orders') }}
),
sessions as (
    select sum(purchase_revenue_usd) as revenue from {{ ref('fct_sessions') }}
)
select orders.revenue as order_revenue, sessions.revenue as session_revenue
from orders, sessions
where abs(orders.revenue - sessions.revenue) > 0.02 * greatest(orders.revenue, sessions.revenue)
