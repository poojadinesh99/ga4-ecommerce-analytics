{#-
  One row per GA4 event, with the event_params we need flattened into columns.
  A session key is user_pseudo_id + ga_session_id (ga_session_id alone is not unique).
-#}
with source as (

    select *
    from {{ source('ga4', 'events') }}
    where _table_suffix between '{{ var("ga4_start_date") }}' and '{{ var("ga4_end_date") }}'

),

flattened as (

    select
        parse_date('%Y%m%d', event_date)              as event_date,
        timestamp_micros(event_timestamp)             as event_ts,
        event_name,
        user_pseudo_id,
        timestamp_micros(user_first_touch_timestamp)  as user_first_touch_ts,

        {{ ga4_param_int('ga_session_id') }}          as ga_session_id,
        {{ ga4_param_int('ga_session_number') }}      as ga_session_number,
        {{ ga4_param_any('session_engaged') }}        as session_engaged,
        {{ ga4_param_int('engagement_time_msec') }}   as engagement_time_msec,

        {{ ga4_param_str('page_location') }}          as page_location,
        {{ ga4_param_str('page_title') }}             as page_title,
        {{ ga4_param_str('page_referrer') }}          as page_referrer,

        -- session-scoped acquisition (logged on the session's first events)
        {{ ga4_param_str('source') }}                 as event_source,
        {{ ga4_param_str('medium') }}                 as event_medium,
        {{ ga4_param_str('campaign') }}               as event_campaign,

        -- user-scoped first-touch acquisition
        traffic_source.source                         as user_first_source,
        traffic_source.medium                         as user_first_medium,
        traffic_source.name                           as user_first_campaign,

        device.category                               as device_category,
        device.operating_system                       as device_os,
        geo.country                                   as country,
        geo.continent                                 as continent,

        nullif(ecommerce.transaction_id, '(not set)') as transaction_id,
        ecommerce.purchase_revenue_in_usd             as purchase_revenue_usd,
        ecommerce.total_item_quantity                 as total_item_quantity

    from source

)

select
    case
        when ga_session_id is not null
        then to_hex(md5(concat(user_pseudo_id, '-', cast(ga_session_id as string))))
    end as session_key,
    *
from flattened
