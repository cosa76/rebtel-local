{{ config(location=storage_path('marts')) }}

select
    p.user_id,
    p.latest_subscription_plan,
    p.total_payments,
    p.total_payment_amount as total_revenue,
    p.avg_payment_amount   as avg_revenue_per_txn,
    p.successful_payments,
    p.failed_payments,
    p.payment_failure_rate_pct,
    coalesce(t.total_transfer_usd, 0) as transfer_volume_usd,
    case when coalesce(c.total_calls, 0) > 0
         then round(p.total_payment_amount / c.total_calls, 2)
         else 0 end as revenue_per_call,
    case when coalesce(t.total_transfers, 0) > 0
         then round(p.total_payment_amount / t.total_transfers, 2)
         else 0 end as revenue_per_transfer,
    round(p.total_payment_amount + coalesce(t.total_transfer_usd, 0) * 0.05, 2) as estimated_ltv,
    current_timestamp as refreshed_at
from {{ ref('fct_payments') }} p
left join {{ ref('fct_telecom_calls') }} c on p.user_id = c.user_id
left join {{ ref('fct_financial_transfers') }} t on p.user_id = t.user_id
