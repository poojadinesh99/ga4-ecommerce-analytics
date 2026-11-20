{#-
  One row per item on an e-commerce event (view_item, add_to_cart, begin_checkout, purchase).
  purchase_event_key + item_index identify an item line, so downstream models can keep
  only items from counted (deduplicated) purchases.
-#}
with source as (

    select *
    from {{ source('ga4', 'events') }}
    where _table_suffix between '{{ var("ga4_start_date") }}' and '{{ var("ga4_end_date") }}'
      and event_name in ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')

),

with_keys as (

    select
        *,
        {{ ga4_clean_id('user_pseudo_id') }} as clean_user_pseudo_id,
        {{ ga4_param_int('ga_session_id') }} as ga_session_id,
        {{ ga4_purchase_event_key() }}       as purchase_event_key
    from source

)

select
    parse_date('%Y%m%d', with_keys.event_date)       as event_date,
    timestamp_micros(with_keys.event_timestamp)      as event_ts,
    with_keys.event_name,
    with_keys.clean_user_pseudo_id                   as user_pseudo_id,
    {{ ga4_session_key('with_keys.clean_user_pseudo_id', 'with_keys.ga_session_id') }} as session_key,
    with_keys.purchase_event_key,
    {{ ga4_clean_id('with_keys.ecommerce.transaction_id') }} as transaction_id,

    item_index,
    item.item_id,
    item.item_name,
    item.item_brand,
    item.item_category,
    {{ to_usd('item.price_in_usd') }}                as price_usd,
    item.quantity,
    {{ to_usd('item.item_revenue_in_usd') }}         as item_revenue_usd

from with_keys, unnest(with_keys.items) as item with offset as item_index
where item.item_id is not null
