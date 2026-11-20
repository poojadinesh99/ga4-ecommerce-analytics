{#- One row per item on an e-commerce event (view_item, add_to_cart, begin_checkout, purchase). -#}
with source as (

    select *
    from {{ source('ga4', 'events') }}
    where _table_suffix between '{{ var("ga4_start_date") }}' and '{{ var("ga4_end_date") }}'
      and event_name in ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')

)

select
    parse_date('%Y%m%d', source.event_date)          as event_date,
    timestamp_micros(source.event_timestamp)         as event_ts,
    source.event_name,
    source.user_pseudo_id,
    to_hex(md5(concat(
        source.user_pseudo_id, '-',
        cast({{ ga4_param_int('ga_session_id') }} as string)
    )))                                              as session_key,
    nullif(source.ecommerce.transaction_id, '(not set)') as transaction_id,

    item.item_id,
    item.item_name,
    item.item_brand,
    item.item_category,
    item.price_in_usd,
    item.quantity,
    item.item_revenue_in_usd

from source, unnest(source.items) as item
where item.item_id is not null
