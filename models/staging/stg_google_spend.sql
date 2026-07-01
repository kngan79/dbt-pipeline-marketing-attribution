with source as (
    select * from {{ ref('raw_google_spend') }}
),

renamed as (
    select
        cast(date as date) as date,
        campaign_id,
        campaign_name,
        cast(spend as numeric) as spend,
        cast(impressions as int64) as impressions,
        cast(clicks as int64) as clicks,
        'Google' as channel
    from source
)

select * from renamed
