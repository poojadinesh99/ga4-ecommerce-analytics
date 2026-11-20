{#-
  Long format of fct_funnel_daily (one row per date x channel x device x step).
  This is the shape Tableau wants for a funnel bar chart with filters.
-#}
{% for step in funnel_steps() %}
select
    session_date,
    channel_group,
    device_category,
    {{ step.order }}        as step_order,
    '{{ step.name }}'       as step_name,
    {{ step.name }}_sessions as sessions
from {{ ref('fct_funnel_daily') }}
{% if not loop.last %}union all{% endif %}
{% endfor %}
