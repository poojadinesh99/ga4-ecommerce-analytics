{#-
  Simplified version of the GA4 default channel grouping, applied to the
  session-scoped source / medium / campaign.
  The obfuscated sample replaces some values with '<Other>' or '(data deleted)';
  those get their own bucket so they are not silently counted as Direct.
-#}
{% macro channel_group(source, medium, campaign) -%}
case
  when {{ source }} in ('<Other>', '(data deleted)')
    or {{ medium }} in ('<Other>', '(data deleted)')
    then 'Unattributed (obfuscated)'
  when ({{ source }} is null or {{ source }} = '(direct)')
    and ({{ medium }} is null or {{ medium }} in ('(none)', '(not set)'))
    then 'Direct'
  when regexp_contains({{ medium }}, r'^(cpc|ppc|paidsearch|paid_search)$')
    and regexp_contains({{ source }}, r'google|bing|yahoo|baidu|duckduckgo|yandex')
    then 'Paid Search'
  when regexp_contains({{ medium }}, r'^(display|banner|expandable|interstitial|cpm)$')
    then 'Display'
  when regexp_contains({{ medium }}, r'^(.*cp.*|ppc|retargeting|paid.*)$')
    then 'Paid Other'
  when {{ medium }} = 'organic'
    or regexp_contains({{ source }}, r'google|bing|yahoo|baidu|duckduckgo|yandex')
    then 'Organic Search'
  when regexp_contains({{ medium }}, r'^(social|social-network|social-media|sm|social network|social media)$')
    or regexp_contains({{ source }}, r'facebook|instagram|linkedin|twitter|t\.co|pinterest|reddit|youtube|tiktok')
    then 'Organic Social'
  when regexp_contains({{ medium }}, r'email|e-mail|e_mail|e mail')
    then 'Email'
  when {{ medium }} = 'affiliate'
    then 'Affiliates'
  when {{ medium }} = 'referral'
    then 'Referral'
  else 'Unassigned'
end
{%- endmacro %}
