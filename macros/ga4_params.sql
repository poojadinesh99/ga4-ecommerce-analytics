{#- Pull a single value out of the GA4 event_params array. -#}
{% macro ga4_param_str(key) -%}
  (select value.string_value from unnest(event_params) where key = '{{ key }}')
{%- endmacro %}

{% macro ga4_param_int(key) -%}
  (select value.int_value from unnest(event_params) where key = '{{ key }}')
{%- endmacro %}

{#- Some params are logged as string in one place and int in another (e.g. session_engaged). -#}
{% macro ga4_param_any(key) -%}
  (select coalesce(value.string_value, cast(value.int_value as string),
                   cast(value.double_value as string), cast(value.float_value as string))
   from unnest(event_params) where key = '{{ key }}')
{%- endmacro %}
