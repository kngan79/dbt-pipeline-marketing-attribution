{{
    config(
        materialized='incremental',
        unique_key='performance_key'
    )
}}

with daily_spend as (
    select
        date,
        channel,
        sum(spend) as total_spend,
        sum(impressions) as total_impressions,
        sum(clicks) as total_clicks
    from {{ ref('int_daily_ad_spend') }}
    group by 1, 2
),

daily_attributed_orders as (
    select
        att.attribution_date as date,
        att.channel,
        count(distinct ord.order_id) as total_orders,
        sum(ord.order_value * att.revenue_share_pct) as attributed_revenue
    from {{ ref('stg_orders') }} ord
    join {{ ref('stg_attribution') }} att 
        on ord.order_id = att.order_id
    where ord.status = 'completed'
    group by 1, 2
),

joined as (
    select
        -- Unique surrogate key to prevent duplicate rows on incremental updates
        to_hex(sha256(concat(
            coalesce(cast(s.date as string), cast(a.date as string)),
            '-',
            coalesce(s.channel, a.channel)
        ))) as performance_key,
        
        coalesce(s.date, a.date) as date,
        coalesce(s.channel, a.channel) as channel,
        coalesce(s.total_spend, 0) as total_spend,
        coalesce(s.total_impressions, 0) as total_impressions,
        coalesce(s.total_clicks, 0) as total_clicks,
        coalesce(a.total_orders, 0) as total_orders,
        coalesce(a.attributed_revenue, 0) as attributed_revenue
    from daily_spend s
    full outer join daily_attributed_orders a
        on s.date = a.date 
        and s.channel = a.channel
)

select
    performance_key,
    date,
    channel,
    total_spend,
    total_impressions,
    total_clicks,
    total_orders,
    attributed_revenue,
    
    case 
        when total_spend > 0 then safe_divide(attributed_revenue, total_spend)
        else 0 
    end as roas,
    
    case 
        when total_orders > 0 then safe_divide(total_spend, total_orders)
        else 0 
    end as cac
from joined

{% if is_incremental() %}
    -- Filter to only run on dates that are equal to or newer than the latest date in the table
    where date >= (select max(date) from {{ this }})
{% endif %}
