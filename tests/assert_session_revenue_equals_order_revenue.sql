-- Session revenue and order revenue are built from the same deduplicated purchases,
-- so for orders that belong to a session they must match exactly: same transaction
-- count, and revenue equal to the cent. There is no percentage tolerance. The only
-- slack is $0.01 for FLOAT64 summation order. Orders without a session (no ga_session_id)
-- are excluded on the order side because they cannot appear in fct_sessions.
-- How raw purchase events map to orders is broken down in analyses/revenue_bridge.sql.
with sessions as (
    select sum(transactions) as transactions, sum(purchase_revenue_usd) as revenue
    from {{ ref('fct_sessions') }}
),
orders as (
    select count(*) as transactions, sum(revenue_usd) as revenue
    from {{ ref('fct_orders') }}
    where session_key is not null
)
select
    sessions.transactions as session_transactions,
    orders.transactions   as order_transactions,
    sessions.revenue      as session_revenue,
    orders.revenue        as order_revenue
from sessions, orders
where sessions.transactions != orders.transactions
   or abs(sessions.revenue - orders.revenue) > 0.01
