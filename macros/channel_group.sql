{#-
  Simplified version of GA4's default channel grouping, applied to the source / medium
  logged in the session (see int_ga4__sessions). It is NOT GA4's official session
  attribution: GA4 also applies non-direct last click across earlier sessions, which
  this per-session rule cannot do.

  Two kinds of "unknown" are kept apart from Direct:
    Unattributed (not logged)     no source or medium was logged in the session
    Unattributed (obfuscated)     the medium was replaced with '<Other>' / '(data deleted)',
                                  or there is no medium and the source is obfuscated
  Direct means the session explicitly logged source '(direct)'.
  An obfuscated source with a usable medium is still classified by medium
  (e.g. '<Other>' / organic -> Organic Search).

  Search engines are matched as whole host names, not substrings: 'google' anywhere
  would otherwise classify shop.googlemerchandisestore.com (the store's own referral)
  and analytics.google.com as search. Found on the first real run.
-#}
{% macro channel_group(source, medium, campaign) -%}
{%- set s = "lower(" ~ source ~ ")" -%}
{%- set m = "lower(" ~ medium ~ ")" -%}
{%- set search = "r'^(www\\.)?(google|bing|yahoo|baidu|duckduckgo|yandex|ecosia|ask)(\\.[a-z]{2,3}){0,2}$'" -%}
{%- set social = "r'^((www|m|l|lm)\\.)?(facebook|instagram|linkedin|lnkd|twitter|x|t|pinterest|reddit|youtube|tiktok|quora)(\\.[a-z]{2,3}){1,2}$|^(facebook|instagram|linkedin|twitter|pinterest|reddit|youtube|tiktok)$'" -%}
case
  when {{ source }} is null and {{ medium }} is null
    then 'Unattributed (not logged)'
  when {{ m }} in ('<other>', '(data deleted)')
    or ({{ medium }} is null and {{ s }} in ('<other>', '(data deleted)'))
    then 'Unattributed (obfuscated)'
  when {{ s }} = '(direct)' and coalesce({{ m }}, '(none)') in ('(none)', '(not set)')
    then 'Direct'
  when regexp_contains({{ m }}, r'^(cpc|ppc|paidsearch|paid_search)$')
    and regexp_contains({{ s }}, {{ search }})
    then 'Paid Search'
  when regexp_contains({{ m }}, r'^(display|banner|expandable|interstitial|cpm)$')
    then 'Display'
  when regexp_contains({{ m }}, r'^(.*cp.*|ppc|retargeting|paid.*)$')
    then 'Paid Other'
  when {{ m }} = 'organic'
    or regexp_contains({{ s }}, {{ search }})
    then 'Organic Search'
  when regexp_contains({{ m }}, r'^(social|social-network|social-media|sm|social network|social media)$')
    or regexp_contains({{ s }}, {{ social }})
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
