{{ config(location=storage_path('marts')) }}

select
    'OVERALL' as dimension,
    count(*)                             as total_calls,
    count_if(connection_success = true)  as connected_calls,
    count_if(connection_success = false) as dropped_calls,
    round(count_if(connection_success = true) * 100.0 / nullif(count(*), 0), 2) as connection_success_rate_pct,
    round(avg(duration_seconds), 2)      as avg_call_duration_sec,
    round(avg(call_quality_score), 2)    as avg_mos_score,
    round(avg(delivery_rate_percent), 2) as avg_delivery_rate_pct,
    count_if(quality_tier = 'excellent') as excellent_calls,
    count_if(quality_tier = 'good')      as good_calls,
    count_if(quality_tier = 'fair')      as fair_calls,
    count_if(quality_tier = 'poor')      as poor_calls,
    round(count_if(call_quality_score >= 3.0) * 100.0 / nullif(count(*), 0), 2) as sla_quality_met_pct,
    round(count_if(connection_success = true) * 100.0 / nullif(count(*), 0), 2) as sla_connection_met_pct,
    count_if(call_duration_bucket = 'no_connection') as calls_no_connection,
    count_if(call_duration_bucket = 'very_short')    as calls_very_short,
    count_if(call_duration_bucket = 'short')         as calls_short,
    count_if(call_duration_bucket = 'medium')        as calls_medium,
    count_if(call_duration_bucket = 'long')          as calls_long,
    current_timestamp as refreshed_at
from {{ ref('stg_stream_cdrs') }}
