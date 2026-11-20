{#-
  Daily funnel counts by channel and device. Wide format, two columns per step:
    <step>_sessions_observed  sessions where GA4 logged that event
    <step>_sessions_inferred  sessions that reached that step or a deeper one (monotonic)
-#}
select
    session_date,
    channel_group,
    device_category,
    count(*)                        as sessions,
    count(distinct user_pseudo_id)  as users,
    countif(is_engaged)             as engaged_sessions,
    {% for step in funnel_steps() -%}
    countif({{ step.observed_column }}) as {{ step.name }}_sessions_observed,
    countif({{ step.inferred_column }}) as {{ step.name }}_sessions_inferred,
    {% endfor -%}
    sum(transactions)               as transactions,
    sum(purchase_revenue_usd)       as purchase_revenue_usd
from {{ ref('fct_sessions') }}
group by session_date, channel_group, device_category
