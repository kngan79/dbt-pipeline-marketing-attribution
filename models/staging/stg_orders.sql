with source as (
    select * from {{ ref('raw_orders') }}
),

renamed as (
    select
        order_id,
        customer_id,
        -- Hash customer email to comply with PII privacy regulations (GDPR/CCPA)
        to_hex(sha256(lower(trim(customer_email)))) as hashed_customer_email,
        customer_name,
        cast(order_date as timestamp) as order_timestamp,
        date(order_date) as order_date,
        cast(order_value as numeric) as order_value,
        status
    from source
),

-- Deduplicate orders to ensure we only process the latest update per order_id
deduped as (
    select * from (
        select 
            *,
            row_number() over (partition by order_id order by order_timestamp desc) as rn
        from renamed
    )
    where rn = 1
)

select 
    order_id,
    customer_id,
    hashed_customer_email,
    customer_name,
    order_timestamp,
    order_date,
    order_value,
    status
from deduped
