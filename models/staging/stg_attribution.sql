with source as (
    select * from {{ ref('raw_attribution') }}
),

renamed as (
    select
        order_id,
        cast(attribution_date as date) as attribution_date,
        lower(channel) as channel,
        campaign_id,
        campaign_name,
        cast(revenue_share_pct as numeric) as revenue_share_pct
    from source
)

select * from renamed
