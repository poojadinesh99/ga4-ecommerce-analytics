-- Monitoring check (warn): duplicate purchase rows for one transaction_id should agree on
-- user and revenue. Disagreement means "keep the earliest" is a choice that changes
-- revenue, or that obfuscation reused an id across users. Returns the affected ids.
{{ config(severity = 'warn') }}

select
    transaction_id,
    count(*)                         as purchase_rows,
    count(distinct user_pseudo_id)   as users,
    count(distinct revenue_usd)      as distinct_revenues
from {{ ref('int_ga4__purchases') }}
where transaction_id is not null
group by transaction_id
having count(*) > 1
   and (count(distinct user_pseudo_id) > 1 or count(distinct revenue_usd) > 1)
