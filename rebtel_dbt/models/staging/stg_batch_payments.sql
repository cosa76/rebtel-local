{{ config(location=storage_path('staging')) }}

select
    transaction_id,
    user_id,
    lower(trim(subscription_plan))        as subscription_plan,
    round(coalesce(payment_amount, 0), 2) as payment_amount,
    lower(trim(payment_status))           as payment_status,
    lower(trim(payment_status)) in ('completed', 'success', 'paid') as is_payment_successful
from {{ source('raw', 'raw_batch_payments') }}
where transaction_id is not null and user_id is not null
