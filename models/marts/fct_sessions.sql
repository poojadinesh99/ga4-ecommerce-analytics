{#-
  Session fact table. Two kinds of funnel flags:
    has_<event>      observed: GA4 logged this event in the session
    reached_<step>   inferred: the session got to this step or a deeper one, so a
                     purchase implies checkout even when begin_checkout was not logged.
                     Monotonic by construction; use for the funnel shape only.
  transactions / purchase_revenue_usd come from deduplicated orders (int_ga4__purchases),
  so a session can have has_purchase = true and transactions = 0 (duplicate or missing
  transaction_id).
-#}
with sessions as (

    select * from {{ ref('int_ga4__sessions') }}

),

with_depth as (

    select
        *,
        case
            when has_purchase       then 5
            when has_begin_checkout then 4
            when has_add_to_cart    then 3
            when has_view_item      then 2
            else 1
        end as funnel_depth
    from sessions

)

select
    session_key,
    user_pseudo_id,
    -- New vs returning, from GA4's ga_session_number for this user_pseudo_id
    -- (a browser/device cookie, not a person). 'unknown' when GA4 sent no number.
    session_number,
    case
        when session_number = 1 then 'new'
        when session_number > 1 then 'returning'
        else 'unknown'
    end                                                  as user_type,
    case when session_number is not null then session_number = 1 end as is_new_user,
    has_first_visit,
    session_date,
    session_start_ts,
    session_end_ts,
    timestamp_diff(session_end_ts, session_start_ts, second) as session_duration_seconds,

    -- Attribution from event params logged in the session (see int_ga4__sessions).
    -- NULL source/medium means nothing was logged; it is not assumed to be Direct.
    attribution_basis,
    session_source,
    session_medium,
    session_campaign,
    {{ channel_group('session_source', 'session_medium', 'session_campaign') }} as channel_group,
    user_first_source,
    user_first_medium,

    coalesce(device_category, '(not set)')               as device_category,
    device_os,
    country,
    continent,
    landing_page,

    is_engaged,
    engagement_seconds,
    event_count,
    page_views,

    has_view_item,
    has_add_to_cart,
    has_begin_checkout,
    has_add_shipping_info,
    has_add_payment_info,
    has_purchase,

    funnel_depth,
    true              as reached_session,
    funnel_depth >= 2 as reached_view_item,
    funnel_depth >= 3 as reached_add_to_cart,
    funnel_depth >= 4 as reached_begin_checkout,
    funnel_depth >= 5 as reached_purchase,

    transactions,
    purchase_revenue_usd

from with_depth
