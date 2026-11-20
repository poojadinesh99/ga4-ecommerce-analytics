{#-
  Treat the sample's placeholder values as missing. The dataset documentation says
  fields can hold '<Other>', NULL or '' because of obfuscation; '(not set)' is GA4's own
  placeholder. Used for identifiers, where a placeholder would merge unrelated records.
-#}
{% macro ga4_clean_id(expr) -%}
  case
    when trim({{ expr }}) in ('', '(not set)', '<Other>', '(data deleted)') then null
    else {{ expr }}
  end
{%- endmacro %}

{#- Blank strings to NULL, for descriptive fields such as source / medium. -#}
{% macro ga4_blank_to_null(expr) -%}
  nullif(trim({{ expr }}), '')
{%- endmacro %}

{#-
  Session key. NULL unless both parts are present. Hashing a JSON struct, not a
  delimiter-joined string, makes the encoding unambiguous: ('a-1', 2) and ('a', '1-2')
  can never collide.
-#}
{% macro ga4_session_key(user_pseudo_id, ga_session_id) -%}
  case
    when {{ user_pseudo_id }} is not null and {{ ga_session_id }} is not null
    then to_hex(sha256(to_json_string(struct(
        {{ user_pseudo_id }} as user_pseudo_id,
        {{ ga_session_id }}  as ga_session_id
    ))))
  end
{%- endmacro %}

{#-
  Identity of one purchase event row, computed from the raw source columns. GA4 has no
  event id, so this hashes the fields that define the event, including the full ecommerce
  record and items array. Byte-identical duplicate rows get the same key. Only call it
  on rows of the raw export (a `source` CTE).
-#}
{% macro ga4_purchase_event_key() -%}
  case
    when event_name = 'purchase'
    then to_hex(sha256(to_json_string(struct(
        user_pseudo_id, event_timestamp, event_name, event_bundle_sequence_id,
        ecommerce, items
    ))))
  end
{%- endmacro %}

{#- Money: FLOAT64 in the export, so round to cents as NUMERIC to keep sums exact. -#}
{% macro to_usd(expr) -%}
  round(cast({{ expr }} as numeric), 2)
{%- endmacro %}
