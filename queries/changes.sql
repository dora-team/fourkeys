# Changes Table
SELECT 
source,
event_type,
JSON_EXTRACT_SCALAR(commit, '$.id') change_id,
TIMESTAMP_TRUNC(TIMESTAMP(JSON_EXTRACT_SCALAR(commit, '$.timestamp')),second) as time_created,
FROM four_keys.events_raw e,
UNNEST(JSON_EXTRACT_ARRAY(e.metadata, '$.commits')) as commit
WHERE event_type = "push"
GROUP BY 1,2,3,4