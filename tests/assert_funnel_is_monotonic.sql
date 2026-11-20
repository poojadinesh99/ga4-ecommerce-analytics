-- The inferred (cumulative) funnel must never increase from one step to the next,
-- for every date / channel / device. Observed counts are not tested this way:
-- GA4 can legitimately log e.g. add_to_cart without view_item.
{% set steps = funnel_steps() %}
select *
from {{ ref('fct_funnel_daily') }}
where false
{% for i in range(1, steps | length) %}
   or {{ steps[i].name }}_sessions_inferred > {{ steps[i - 1].name }}_sessions_inferred
{% endfor %}
