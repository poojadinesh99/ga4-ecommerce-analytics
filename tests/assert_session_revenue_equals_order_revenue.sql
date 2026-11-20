-- Session revenue and order revenue are built from the same counted purchases, so for
-- orders that belong to a session they must match exactly. Revenue is NUMERIC rounded
-- to cents, so this is exact equality with no tolerance.
-- Orders without a session (has_session = false) are excluded on the order side,
-- because they cannot appear in fct_sessions. Their share is in analyses/revenue_bridge.sql.
with sessions as (
    select sum(transactions) as transactions, coalesce(sum(purchase_revenue_usd), 0) as revenue
    from {{ ref('fct_sessions') }}
),
orders as (
    select count(*) as transactions, coalesce(sum(revenue_usd), 0) as revenue
    from {{ ref('fct_orders') }}
    where has_session
)
select
    sessions.transactions as session_transactions,
    orders.transactions   as order_transactions,
    sessions.revenue      as session_revenue,
    orders.revenue        as order_revenue
from sessions, orders
where sessions.transactions != orders.transactions
   or sessions.revenue != orders.revenue
