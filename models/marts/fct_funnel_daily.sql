{#- Daily funnel counts by channel and device. Wide format: one column per step. -#}
select
    session_date,
    channel_group,
    device_category,
    count(*)                        as sessions,
    count(distinct user_pseudo_id)  as users,
    countif(is_engaged)             as engaged_sessions,
    {% for step in funnel_steps() -%}
    countif({{ step.column }})      as {{ step.name }}_sessions,
    {% endfor -%}
    sum(transactions)               as transactions,
    sum(purchase_revenue_usd)       as purchase_revenue_usd
from {{ ref('fct_sessions') }}
group by session_date, channel_group, device_category
