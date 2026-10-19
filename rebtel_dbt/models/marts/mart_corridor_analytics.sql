{{ config(location=storage_path('marts')) }}

select
    sender_country,
    receiver_country,
    corridor,
    count(*)                           as total_transfers,
    count(distinct user_id)            as unique_senders,
    round(sum(transfer_amount_usd), 2) as total_volume_usd,
    round(avg(transfer_amount_usd), 2) as avg_transfer_usd,
    round(max(transfer_amount_usd), 2) as max_transfer_usd,
    count_if(is_fraud_flag = true)     as fraud_count,
    round(count_if(is_fraud_flag = true) * 100.0 / nullif(count(*), 0), 2) as fraud_rate_pct,
    count_if(transfer_size_tier = 'micro')      as micro_transfers,
    count_if(transfer_size_tier = 'small')      as small_transfers,
    count_if(transfer_size_tier = 'medium')     as medium_transfers,
    count_if(transfer_size_tier = 'large')      as large_transfers,
    count_if(transfer_size_tier = 'very_large') as very_large_transfers,
    case
        when count_if(is_fraud_flag = true) > 5
          or round(count_if(is_fraud_flag = true) * 100.0 / nullif(count(*), 0), 2) > 10
            then 'HIGH_RISK_CORRIDOR'
        when count_if(is_fraud_flag = true) > 0
            then 'MONITOR_CORRIDOR'
        else 'SAFE_CORRIDOR'
    end as corridor_risk,
    current_timestamp as refreshed_at
from {{ ref('stg_stream_transfers') }}
group by sender_country, receiver_country, corridor
