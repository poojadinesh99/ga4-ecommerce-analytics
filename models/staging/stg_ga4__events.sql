{#-
  One row per GA4 event, with the event_params we need flattened into columns.
  Identifiers are cleaned of placeholder values (see macros/ga4_identity.sql) and
  money is cast to NUMERIC cents.
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
        {{ ga4_clean_id('user_pseudo_id') }}          as user_pseudo_id,
        timestamp_micros(user_first_touch_timestamp)  as user_first_touch_ts,
        {{ ga4_purchase_event_key() }}                as purchase_event_key,

        {{ ga4_param_int('ga_session_id') }}          as ga_session_id,
        {{ ga4_param_int('ga_session_number') }}      as ga_session_number,
        {{ ga4_param_any('session_engaged') }}        as session_engaged,
        {{ ga4_param_int('engagement_time_msec') }}   as engagement_time_msec,

        {{ ga4_param_str('page_location') }}          as page_location,
        {{ ga4_param_str('page_title') }}             as page_title,
        {{ ga4_param_str('page_referrer') }}          as page_referrer,

        -- Traffic source as logged on this event. GA4 puts the session's attribution
        -- inputs on session_start; these are inputs, not GA4's final session attribution.
        {{ ga4_blank_to_null(ga4_param_str('source')) }}   as event_source,
        {{ ga4_blank_to_null(ga4_param_str('medium')) }}   as event_medium,
        {{ ga4_blank_to_null(ga4_param_str('campaign')) }} as event_campaign,

        -- User-scoped first-touch acquisition (never changes for the user)
        traffic_source.source                         as user_first_source,
        traffic_source.medium                         as user_first_medium,
        traffic_source.name                           as user_first_campaign,

        device.category                               as device_category,
        device.operating_system                       as device_os,
        geo.country                                   as country,
        geo.continent                                 as continent,

        {{ ga4_clean_id('ecommerce.transaction_id') }} as transaction_id,
        {{ to_usd('ecommerce.purchase_revenue_in_usd') }} as purchase_revenue_usd,
        ecommerce.total_item_quantity                 as total_item_quantity

    from source

)

select
    {{ ga4_session_key('user_pseudo_id', 'ga_session_id') }} as session_key,
    *
from flattened
