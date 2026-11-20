-- Monitoring check (warn): transaction_ids used by more than one user. In this
-- obfuscated sample these are treated as different orders (see int_ga4__purchases).
-- Returns them so the count is visible in every run; 15 on the full sample.
{{ config(severity = 'warn', warn_if = '>50') }}

select transaction_id, count(distinct user_pseudo_id) as users
from {{ ref('int_ga4__purchases') }}
where purchase_status = 'counted'
group by transaction_id
having count(distinct user_pseudo_id) > 1
