{#- Single source of truth for the funnel definition, used by several models and tests. -#}
{% macro funnel_steps() %}
  {{ return([
    {"order": 1, "name": "session_start",  "column": "reached_session"},
    {"order": 2, "name": "view_item",      "column": "reached_view_item"},
    {"order": 3, "name": "add_to_cart",    "column": "reached_add_to_cart"},
    {"order": 4, "name": "begin_checkout", "column": "reached_begin_checkout"},
    {"order": 5, "name": "purchase",       "column": "reached_purchase"},
  ]) }}
{% endmacro %}
