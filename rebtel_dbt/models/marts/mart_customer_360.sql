{{ config(location=storage_path('marts')) }}

with calls as (
    select * from {{ ref('fct_telecom_calls') }}
),
transfers as (
    select * from {{ ref('fct_financial_transfers') }}
),
tickets as (
    select * from {{ ref('fct_support_tickets') }}
),
payments as (
    select * from {{ ref('fct_payments') }}
),
fraud as (
    select user_id, fraud_risk_level from {{ ref('mart_fraud_prevention') }}
)
select
    coalesce(c.user_id, t.user_id, k.user_id, p.user_id) as user_id,
    coalesce(c.total_calls, 0)     as total_calls,
    coalesce(t.total_transfers, 0) as total_transfers,
    coalesce(p.total_payments, 0)  as total_payments,
    coalesce(k.total_tickets, 0)   as total_support_tickets,
    coalesce(c.total_calls, 0) + coalesce(t.total_transfers, 0) + coalesce(p.total_payments, 0) as total_activity_events,
    coalesce(p.total_payment_amount, 0) as total_revenue,
    coalesce(t.total_transfer_usd, 0)   as total_transfer_volume_usd,
    p.latest_subscription_plan,
    coalesce(c.avg_quality_score, 0)      as call_quality_score,
    coalesce(c.call_failure_rate_pct, 0)  as call_failure_rate_pct,
    coalesce(k.avg_satisfaction_score, 0) as support_satisfaction_score,
    coalesce(k.avg_resolution_hours, 0)   as avg_ticket_resolution_hours,
    f.fraud_risk_level,
    coalesce(p.payment_failure_rate_pct, 0) as payment_failure_rate_pct,
    -- Customer Health Score (0-100)
    round(
        (coalesce(c.avg_quality_score, 3) / 5.0 * 25)
        + (coalesce(k.avg_satisfaction_score, 3) / 5.0 * 25)
        + (case when coalesce(c.call_failure_rate_pct, 0) < 10 then 25
                when coalesce(c.call_failure_rate_pct, 0) < 25 then 15
                when coalesce(c.call_failure_rate_pct, 0) < 50 then 5
                else 0 end)
        + (case when f.fraud_risk_level in ('SAFE', 'LOW_RISK') then 25
                when f.fraud_risk_level = 'MEDIUM_RISK' then 10
                else 0 end)
    , 1) as customer_health_score,
    case
        when coalesce(p.total_payment_amount, 0) > 500
             and coalesce(c.total_calls, 0) > 50
             and coalesce(t.total_transfers, 0) > 20    then 'VIP'
        when coalesce(p.total_payment_amount, 0) > 200
             or coalesce(t.total_transfer_usd, 0) > 500 then 'HIGH_VALUE'
        when coalesce(c.total_calls, 0) > 30
             or coalesce(t.total_transfers, 0) > 10     then 'ACTIVE'
        when coalesce(c.total_calls, 0) > 0
             or coalesce(t.total_transfers, 0) > 0      then 'REGULAR'
        else 'INACTIVE'
    end as customer_segment,
    case
        when coalesce(k.total_tickets, 0) > 3
             and coalesce(k.avg_satisfaction_score, 5) < 3.0
             and coalesce(c.call_failure_rate_pct, 0) > 20 then 'HIGH_CHURN_RISK'
        when coalesce(k.total_tickets, 0) > 2
             or coalesce(k.avg_satisfaction_score, 5) < 3.0 then 'MODERATE_CHURN_RISK'
        else 'STABLE'
    end as churn_risk,
    current_timestamp as refreshed_at
from calls c
full outer join transfers t on c.user_id = t.user_id
full outer join tickets   k on coalesce(c.user_id, t.user_id) = k.user_id
full outer join payments  p on coalesce(c.user_id, t.user_id, k.user_id) = p.user_id
left join fraud f on coalesce(c.user_id, t.user_id, k.user_id, p.user_id) = f.user_id
