-- Bridge from raw GA4 purchase events to counted orders.
-- Explains every dollar between "sum of purchase_revenue on purchase events"
-- and fct_orders / session revenue.
select
    purchase_status,
    session_key is not null      as has_session,
    count(*)                     as purchase_events,
    count(distinct transaction_id) as distinct_transactions,
    round(sum(revenue_usd), 2)   as revenue_usd,
    round(safe_divide(sum(revenue_usd), sum(sum(revenue_usd)) over ()), 4) as share_of_raw_revenue
from {{ ref('int_ga4__purchases') }}
group by 1, 2
order by 1, 2
