{#-
  Single source of truth for the funnel definition, used by several models and tests.
    observed_column: the session logged this GA4 event (what GA4 actually recorded)
    inferred_column: the session reached this step or a deeper one (cumulative progression)
-#}
{% macro funnel_steps() %}
  {{ return([
    {"order": 1, "name": "session_start",  "observed_column": "true",               "inferred_column": "reached_session"},
    {"order": 2, "name": "view_item",      "observed_column": "has_view_item",      "inferred_column": "reached_view_item"},
    {"order": 3, "name": "add_to_cart",    "observed_column": "has_add_to_cart",    "inferred_column": "reached_add_to_cart"},
    {"order": 4, "name": "begin_checkout", "observed_column": "has_begin_checkout", "inferred_column": "reached_begin_checkout"},
    {"order": 5, "name": "purchase",       "observed_column": "has_purchase",       "inferred_column": "reached_purchase"},
  ]) }}
{% endmacro %}
