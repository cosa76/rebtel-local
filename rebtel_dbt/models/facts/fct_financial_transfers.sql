{{ config(location=storage_path('marts')) }}

select
    user_id,
    count(*)                                    as total_transfers,
    round(sum(transfer_amount_usd), 2)          as total_transfer_usd,
    round(avg(transfer_amount_usd), 2)          as avg_transfer_usd,
    round(max(transfer_amount_usd), 2)          as max_transfer_usd,
    round(min(transfer_amount_usd), 2)          as min_transfer_usd,
    count_if(is_fraud_flag = true)              as fraud_transfers,
    round(count_if(is_fraud_flag = true) * 100.0 / nullif(count(*), 0), 2) as fraud_rate_pct,
    count(distinct sender_country)              as distinct_sender_countries,
    count(distinct receiver_country)            as distinct_receiver_countries,
    count(distinct corridor)                    as distinct_corridors,
    count_if(transfer_size_tier = 'very_large') as very_large_transfers,
    count_if(transfer_size_tier = 'micro')      as micro_transfers
from {{ ref('stg_stream_transfers') }}
group by user_id
