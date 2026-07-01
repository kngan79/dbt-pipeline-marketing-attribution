with source as (
    select * from {{ ref('raw_fb_spend') }}
),

renamed as (
    select
        cast(date as date) as date,
        campaign_id,
        campaign_name,
        cast(spend as numeric) as spend,
        cast(impressions as int64) as impressions,
        cast(clicks as int64) as clicks,
        'Facebook' as channel
    from source
)

select * from renamed
