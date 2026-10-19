{{ config(location=storage_path('marts')) }}

select
    user_id,
    count(*)                                 as total_payments,
    round(sum(payment_amount), 2)            as total_payment_amount,
    round(avg(payment_amount), 2)            as avg_payment_amount,
    count_if(is_payment_successful = true)   as successful_payments,
    count_if(is_payment_successful = false)  as failed_payments,
    round(count_if(is_payment_successful = false) * 100.0 / nullif(count(*), 0), 2) as payment_failure_rate_pct,
    count(distinct subscription_plan)        as distinct_plans,
    -- Même approximation que dbt_runner.py : MAX alphabétique, pas le plan le plus récent
    max(subscription_plan)                   as latest_subscription_plan
from {{ ref('stg_batch_payments') }}
group by user_id
