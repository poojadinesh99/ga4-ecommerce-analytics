{#-
  One row per session. Aggregates events, picks the session's acquisition
  source / landing page, and flags which funnel events happened.
-#}
with events as (

    select *
    from {{ ref('stg_ga4__events') }}
    where session_key is not null

),

session_source as (

    -- GA4 records a session's attribution inputs on its session_start event, so prefer
    -- that event; otherwise fall back to the earliest event that logged a source or medium.
    select
        session_key,
        event_source   as session_source,
        event_medium   as session_medium,
        event_campaign as session_campaign,
        if(event_name = 'session_start', 'session_start_params', 'other_event_params')
                       as attribution_basis
    from events
    where event_source is not null or event_medium is not null
    qualify row_number() over (
        partition by session_key
        order by if(event_name = 'session_start', 0, 1), event_ts
    ) = 1

),

landing_page as (

    select
        session_key,
        page_location as landing_page
    from events
    where event_name = 'page_view'
    qualify row_number() over (partition by session_key order by event_ts) = 1

),

aggregated as (

    select
        session_key,
        any_value(user_pseudo_id)                          as user_pseudo_id,
        any_value(ga_session_id)                           as ga_session_id,
        min(ga_session_number)                             as session_number,
        count(distinct ga_session_number)                  as distinct_session_numbers,
        countif(event_name = 'first_visit') > 0            as has_first_visit,
        min(event_date)                                    as session_date,
        min(event_ts)                                      as session_start_ts,
        max(event_ts)                                      as session_end_ts,

        any_value(device_category)                         as device_category,
        any_value(device_os)                               as device_os,
        any_value(country)                                 as country,
        any_value(continent)                               as continent,
        any_value(user_first_source)                       as user_first_source,
        any_value(user_first_medium)                       as user_first_medium,

        coalesce(logical_or(session_engaged = '1'), false) as is_engaged,
        sum(coalesce(engagement_time_msec, 0)) / 1000      as engagement_seconds,
        count(*)                                           as event_count,
        countif(event_name = 'page_view')                  as page_views,

        countif(event_name = 'view_item')         > 0      as has_view_item,
        countif(event_name = 'add_to_cart')       > 0      as has_add_to_cart,
        countif(event_name = 'begin_checkout')    > 0      as has_begin_checkout,
        countif(event_name = 'add_shipping_info') > 0      as has_add_shipping_info,
        countif(event_name = 'add_payment_info')  > 0      as has_add_payment_info,
        countif(event_name = 'purchase')          > 0      as has_purchase

    from events
    group by session_key

),

-- Revenue comes from deduplicated orders, never from raw purchase events.
session_orders as (

    select
        session_key,
        count(*)         as transactions,
        sum(revenue_usd) as purchase_revenue_usd
    from {{ ref('int_ga4__purchases') }}
    where purchase_status = 'counted'
      and session_key is not null
    group by session_key

)

select
    aggregated.*,
    session_source.session_source,
    session_source.session_medium,
    session_source.session_campaign,
    coalesce(session_source.attribution_basis, 'not_logged') as attribution_basis,
    landing_page.landing_page,
    coalesce(session_orders.transactions, 0)         as transactions,
    coalesce(session_orders.purchase_revenue_usd, 0) as purchase_revenue_usd
from aggregated
left join session_source using (session_key)
left join landing_page using (session_key)
left join session_orders using (session_key)
