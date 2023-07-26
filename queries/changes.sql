# Changes Table
SELECT 
    e.source AS source,
    JSON_EXTRACT_SCALAR(e.metadata, '$.issue.fields.issuetype.name') AS event_type,
    e.repo_name AS repo_name,
    JSON_EXTRACT_SCALAR(e.metadata, '$.issue.key') AS change_id,
    TIMESTAMP_TRUNC(TIMESTAMP(JSON_EXTRACT_SCALAR(e.metadata, '$.issue.fields.statuscategorychangedate')), second) AS time_created,
    JSON_EXTRACT_SCALAR(e.metadata, '$.issue.fields.status.name') AS status
FROM 
    four_keys.events e
WHERE 
    e.event_type = "jira:issue_updated"
GROUP BY 
    1,2,3,4,5,6
