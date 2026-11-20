-- Monitoring check (warn): duplicate rows of one order (same transaction_id and user)
-- should agree on revenue. If they disagree, "keep the earliest row" changes revenue.
-- Returns the affected orders.
{{ config(severity = 'warn') }}

select
    order_key,
    any_value(transaction_id)        as transaction_id,
    count(*)                         as purchase_rows,
    count(distinct revenue_usd)      as distinct_revenues
from {{ ref('int_ga4__purchases') }}
where order_key is not null
group by order_key
having count(*) > 1 and count(distinct revenue_usd) > 1
