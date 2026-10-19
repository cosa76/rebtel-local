{{ config(location=storage_path('marts')) }}

select
    user_id,
    count(*)                                     as total_tickets,
    count_if(issue_category = 'fraud_alert')     as fraud_tickets,
    count_if(issue_category = 'payment_failure') as payment_failure_tickets,
    count_if(issue_category = 'call_drop')       as call_drop_tickets,
    count_if(issue_category = 'topup_delay')     as topup_delay_tickets,
    round(avg(satisfaction_score), 2)            as avg_satisfaction_score,
    round(avg(resolution_hours), 2)              as avg_resolution_hours,
    count_if(ticket_status = 'open')             as open_tickets,
    count_if(ticket_status = 'pending')          as pending_tickets,
    count_if(ticket_status = 'solved')           as solved_tickets,
    count_if(ticket_status = 'closed')           as closed_tickets,
    count_if(priority = 'urgent')                as urgent_tickets,
    count_if(priority = 'high')                  as high_priority_tickets
from {{ ref('stg_airbyte_zendesk') }}
group by user_id
