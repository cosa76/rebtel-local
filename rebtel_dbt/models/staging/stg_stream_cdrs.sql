{{ config(location=storage_path('staging')) }}

select
    call_id,
    user_id,
    coalesce(duration_seconds, 0)                as duration_seconds,
    coalesce(connection_success, false)          as connection_success,
    round(coalesce(call_quality_score, 0), 2)    as call_quality_score,
    round(coalesce(delivery_rate_percent, 0), 2) as delivery_rate_percent,
    cast("timestamp" as timestamp)               as event_timestamp,
    case
        when coalesce(duration_seconds, 0) = 0   then 'no_connection'
        when coalesce(duration_seconds, 0) < 30  then 'very_short'
        when coalesce(duration_seconds, 0) < 120 then 'short'
        when coalesce(duration_seconds, 0) < 600 then 'medium'
        else 'long'
    end as call_duration_bucket,
    case
        when coalesce(call_quality_score, 0) >= 4.0 then 'excellent'
        when coalesce(call_quality_score, 0) >= 3.0 then 'good'
        when coalesce(call_quality_score, 0) >= 2.0 then 'fair'
        else 'poor'
    end as quality_tier
from {{ source('raw', 'raw_stream_cdrs') }}
where call_id is not null and user_id is not null
