-- Total sessions must be identical across fct_sessions, fct_funnel_daily and step 1 of fct_funnel_steps.
with a as (select count(*) as n from {{ ref('fct_sessions') }}),
     b as (select sum(sessions) as n from {{ ref('fct_funnel_daily') }}),
     c as (select sum(sessions_inferred) as n from {{ ref('fct_funnel_steps') }} where step_order = 1)
select a.n as fct_sessions, b.n as funnel_daily, c.n as funnel_steps
from a, b, c
where a.n != b.n or a.n != c.n
