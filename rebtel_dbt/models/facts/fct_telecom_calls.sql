{{ config(location=storage_path('marts')) }}

select
    user_id,
    count(*)                                         as total_calls,
    count_if(connection_success = false)             as failed_calls,
    count_if(connection_success = true)              as successful_calls,
    round(avg(duration_seconds), 2)                  as avg_duration_seconds,
    round(max(duration_seconds), 2)                  as max_duration_seconds,
    round(sum(duration_seconds), 2)                  as total_duration_seconds,
    round(avg(call_quality_score), 2)                as avg_quality_score,
    round(min(call_quality_score), 2)                as min_quality_score,
    round(avg(delivery_rate_percent), 2)             as avg_delivery_rate_pct,
    round(count_if(connection_success = false) * 100.0 / nullif(count(*), 0), 2) as call_failure_rate_pct,
    count_if(call_duration_bucket = 'no_connection') as no_connection_calls,
    count_if(quality_tier = 'poor')                  as poor_quality_calls,
    count_if(quality_tier = 'excellent')             as excellent_quality_calls
from {{ ref('stg_stream_cdrs') }}
group by user_id
