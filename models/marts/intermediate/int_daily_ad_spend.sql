with fb as (
    select 
        date,
        campaign_id,
        campaign_name,
        spend,
        impressions,
        clicks,
        channel
    from {{ ref('stg_fb_spend') }}
),

google as (
    select 
        date,
        campaign_id,
        campaign_name,
        spend,
        impressions,
        clicks,
        channel
    from {{ ref('stg_google_spend') }}
),

unioned as (
    select * from fb
    union all
    select * from google
),

parsed as (
    select
        date,
        campaign_id,
        campaign_name,
        -- Extract tracking token embedded in the campaign name (e.g. Summer_Sale_TokenABC -> TokenABC)
        case 
            when campaign_name like '%Token%' then split(campaign_name, '_Token')[safe_offset(1)]
            else 'Generic'
        end as campaign_token,
        spend,
        impressions,
        clicks,
        channel
    from unioned
)

select * from parsed
