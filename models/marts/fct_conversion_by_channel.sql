{#-
  Channel scorecard: volume, engagement, step-to-step conversion and revenue.
  Step rates use the inferred (cumulative) funnel so they stay within [0, 1].
  purchase_sessions is identical under both definitions (purchase is the last step).
-#}
with by_channel as (

    select
        channel_group,
        count(*)                                as sessions,
        count(distinct user_pseudo_id)          as users,
        countif(user_type = 'new')              as new_user_sessions,
        countif(is_engaged)                     as engaged_sessions,
        -- inferred progression (monotonic), used for the step-to-step rates below
        countif(reached_view_item)              as view_item_sessions,
        countif(reached_add_to_cart)            as add_to_cart_sessions,
        countif(reached_begin_checkout)         as begin_checkout_sessions,
        countif(reached_purchase)               as purchase_sessions,
        -- observed events, for comparison
        countif(has_view_item)                  as view_item_sessions_observed,
        countif(has_add_to_cart)                as add_to_cart_sessions_observed,
        countif(has_begin_checkout)             as begin_checkout_sessions_observed,
        sum(transactions)                       as transactions,
        sum(purchase_revenue_usd)               as purchase_revenue_usd
    from {{ ref('fct_sessions') }}
    group by channel_group

)

select
    *,
    safe_divide(engaged_sessions, sessions)                       as engagement_rate,
    safe_divide(view_item_sessions, sessions)                     as session_to_view_item_rate,
    safe_divide(add_to_cart_sessions, view_item_sessions)         as view_item_to_cart_rate,
    safe_divide(begin_checkout_sessions, add_to_cart_sessions)    as cart_to_checkout_rate,
    safe_divide(purchase_sessions, begin_checkout_sessions)       as checkout_to_purchase_rate,
    safe_divide(purchase_sessions, sessions)                      as session_conversion_rate,
    safe_divide(purchase_revenue_usd, transactions)               as avg_order_value_usd,
    safe_divide(purchase_revenue_usd, sessions)                   as revenue_per_session_usd,
    safe_divide(sessions, sum(sessions) over ())                  as share_of_sessions,
    safe_divide(purchase_revenue_usd, sum(purchase_revenue_usd) over ()) as share_of_revenue
from by_channel
