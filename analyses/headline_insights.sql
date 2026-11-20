-- Queries behind the "Findings" section of the README. Run each in the BigQuery console
-- after `dbt compile`, and only quote numbers that came out of these queries.

-- 1. Overall funnel: inferred and observed, with step-to-step conversion
select
    step_order,
    step_name,
    sum(sessions_inferred) as sessions_inferred,
    sum(sessions_observed) as sessions_observed,
    round(safe_divide(sum(sessions_inferred),
          lag(sum(sessions_inferred)) over (order by step_order)), 3) as conversion_from_previous
from {{ ref('fct_funnel_steps') }}
group by 1, 2
order by 1;

-- 2. Channels: who brings traffic vs who brings revenue
select
    channel_group, sessions,
    round(share_of_sessions, 3)        as share_of_sessions,
    round(share_of_revenue, 3)         as share_of_revenue,
    round(session_conversion_rate, 4)  as conversion_rate,
    round(avg_order_value_usd, 2)      as aov_usd
from {{ ref('fct_conversion_by_channel') }}
order by sessions desc;

-- 3. Device and new vs returning (user_type is per browser/device cookie)
select
    device_category,
    user_type,
    count(*)                                                  as sessions,
    round(safe_divide(countif(reached_add_to_cart), count(*)), 4) as add_to_cart_rate,
    round(safe_divide(countif(reached_purchase), count(*)), 4)    as conversion_rate,
    round(sum(purchase_revenue_usd), 0)                       as revenue_usd
from {{ ref('fct_sessions') }}
group by 1, 2
order by sessions desc;

-- 4. Products viewed a lot but rarely added to cart (min 500 viewing sessions)
select item_name, item_category, view_item_sessions, add_to_cart_sessions,
       round(view_to_cart_rate, 3) as view_to_cart_rate, round(item_revenue_usd, 0) as revenue_usd
from {{ ref('fct_item_performance') }}
where view_item_sessions >= 500
order by view_to_cart_rate
limit 15;
