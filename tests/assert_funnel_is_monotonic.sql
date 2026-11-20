-- Each funnel step must have no more sessions than the step before it.
-- Returns offending rows; the test passes when nothing is returned.
{% set steps = funnel_steps() %}
select *
from {{ ref('fct_funnel_daily') }}
where false
{% for i in range(1, steps | length) %}
   or {{ steps[i].name }}_sessions > {{ steps[i - 1].name }}_sessions
{% endfor %}
