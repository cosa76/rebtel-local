{{ config(location=storage_path('marts')) }}

with cdrs as (
    select * from {{ ref('fct_telecom_calls') }}
),
transfers as (
    select * from {{ ref('fct_financial_transfers') }}
),
tickets as (
    select * from {{ ref('fct_support_tickets') }}
)
select
    coalesce(c.user_id, t.user_id, k.user_id) as user_id,
    c.total_calls,
    c.failed_calls,
    c.call_failure_rate_pct,
    c.avg_quality_score,
    c.avg_delivery_rate_pct,
    c.poor_quality_calls,
    t.total_transfers,
    t.total_transfer_usd,
    t.avg_transfer_usd,
    t.fraud_transfers,
    t.fraud_rate_pct,
    t.very_large_transfers,
    k.total_tickets as support_tickets,
    k.fraud_tickets,
    k.avg_satisfaction_score,
    coalesce(t.fraud_transfers, 0) + coalesce(k.fraud_tickets, 0) as total_fraud_signals,
    case
        when coalesce(t.fraud_transfers, 0) > 0 and coalesce(k.fraud_tickets, 0) > 0
            then 'CRITICAL_RISK'
        when coalesce(t.fraud_transfers, 0) > 0 or coalesce(k.fraud_tickets, 0) > 0
            then 'HIGH_RISK_FRAUD'
        when coalesce(c.call_failure_rate_pct, 0) > 30.0
          or coalesce(t.total_transfer_usd, 0) > 900
          or coalesce(t.very_large_transfers, 0) > 2
            then 'MEDIUM_RISK'
        when coalesce(c.call_failure_rate_pct, 0) > 15.0
          or coalesce(k.total_tickets, 0) > 5
            then 'LOW_RISK'
        else 'SAFE'
    end as fraud_risk_level,
    current_timestamp as mart_refreshed_at
from cdrs c
full outer join transfers t on c.user_id = t.user_id
full outer join tickets   k on coalesce(c.user_id, t.user_id) = k.user_id
