{#-
  Simplified version of GA4's default channel grouping, applied to the source / medium
  logged in the session (see int_ga4__sessions). It is NOT GA4's official session
  attribution: GA4 also applies non-direct last click across earlier sessions, which
  this per-session rule cannot do.

  Two kinds of "unknown" are kept apart from Direct:
    Unattributed (not logged)     no source or medium was logged in the session
    Unattributed (obfuscated)     the sample replaced the value with '<Other>' / '(data deleted)'
  Direct means the session explicitly logged source '(direct)'.
-#}
{% macro channel_group(source, medium, campaign) -%}
{%- set s = "lower(" ~ source ~ ")" -%}
{%- set m = "lower(" ~ medium ~ ")" -%}
case
  when {{ source }} is null and {{ medium }} is null
    then 'Unattributed (not logged)'
  when {{ s }} in ('<other>', '(data deleted)') or {{ m }} in ('<other>', '(data deleted)')
    then 'Unattributed (obfuscated)'
  when {{ s }} = '(direct)' and coalesce({{ m }}, '(none)') in ('(none)', '(not set)')
    then 'Direct'
  when regexp_contains({{ m }}, r'^(cpc|ppc|paidsearch|paid_search)$')
    and regexp_contains({{ s }}, r'google|bing|yahoo|baidu|duckduckgo|yandex')
    then 'Paid Search'
  when regexp_contains({{ m }}, r'^(display|banner|expandable|interstitial|cpm)$')
    then 'Display'
  when regexp_contains({{ m }}, r'^(.*cp.*|ppc|retargeting|paid.*)$')
    then 'Paid Other'
  when {{ m }} = 'organic'
    or regexp_contains({{ s }}, r'google|bing|yahoo|baidu|duckduckgo|yandex')
    then 'Organic Search'
  when regexp_contains({{ m }}, r'^(social|social-network|social-media|sm|social network|social media)$')
    or regexp_contains({{ s }}, r'facebook|instagram|linkedin|twitter|t\.co|pinterest|reddit|youtube|tiktok')
    then 'Organic Social'
  when regexp_contains({{ m }}, r'email|e-mail|e_mail|e mail')
    then 'Email'
  when {{ m }} = 'affiliate'
    then 'Affiliates'
  when {{ m }} = 'referral'
    then 'Referral'
  else 'Unassigned'
end
{%- endmacro %}
