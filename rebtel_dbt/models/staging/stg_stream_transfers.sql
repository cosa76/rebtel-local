{{ config(location=storage_path('staging')) }}

select
    transfer_id,
    user_id,
    upper(trim(sender_country))   as sender_country,
    upper(trim(receiver_country)) as receiver_country,
    round(coalesce(transfer_amount_usd, 0), 2) as transfer_amount_usd,
    coalesce(is_fraud_flag, false) as is_fraud_flag,
    case
        when coalesce(transfer_amount_usd, 0) < 50   then 'micro'
        when coalesce(transfer_amount_usd, 0) < 200  then 'small'
        when coalesce(transfer_amount_usd, 0) < 500  then 'medium'
        when coalesce(transfer_amount_usd, 0) < 1000 then 'large'
        else 'very_large'
    end as transfer_size_tier,
    concat(upper(trim(sender_country)), ' -> ', upper(trim(receiver_country))) as corridor
from {{ source('raw', 'raw_stream_money_transfers') }}
where transfer_id is not null and user_id is not null
