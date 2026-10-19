{{ config(location=storage_path('staging')) }}

select
    ticket_id,
    user_id,
    cast(created_at as timestamp)  as created_at,
    cast(updated_at as timestamp)  as updated_at,
    lower(trim(issue_category))    as issue_category,
    lower(trim(priority))          as priority,
    lower(trim(ticket_status))     as ticket_status,
    satisfaction_score,
    -- Heures pleines écoulées, comme TIMESTAMP_DIFF(..., HOUR) dans BigQuery
    cast(floor(date_diff('second', cast(created_at as timestamp), cast(updated_at as timestamp)) / 3600) as bigint) as resolution_hours
from {{ source('raw', 'raw_airbyte_zendesk_tickets') }}
where ticket_id is not null and user_id is not null
