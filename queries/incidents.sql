SELECT 
incident_id, 
TIMESTAMP(time_created) time_created, 
TIMESTAMP(MAX(time_resolved)) as time_resolved, 
ARRAY_AGG(root_cause IGNORE NULLS) changes, 
FROM (
 SELECT 
 JSON_EXTRACT_SCALAR(metadata, "$.issue.number") as incident_id, 
 JSON_EXTRACT_SCALAR(metadata, "$.issue.created_at") as time_created, 
 JSON_EXTRACT_SCALAR(metadata, "$.issue.closed_at") as time_resolved, 
 REGEXP_EXTRACT(metadata, r"root cause: ([[:alnum:]]*)") as root_cause, 
 REGEXP_CONTAINS(JSON_EXTRACT(metadata, "$.issue.labels"), '"name":"Incident"') as bug 
 FROM four_keys.events_raw 
 WHERE event_type LIKE "issue%"
 ) 
GROUP BY 1,2 
HAVING max(bug) is True;
