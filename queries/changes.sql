# Changes Table
SELECT 
source,
event_type,
repo_name,
JSON_EXTRACT_SCALAR(commit, '$.id') change_id,
TIMESTAMP_TRUNC(TIMESTAMP(JSON_EXTRACT_SCALAR(commit, '$.timestamp')),second) AS time_created,
FROM four_keys.events e,
UNNEST(JSON_EXTRACT_ARRAY(e.metadata, '$.commits')) AS commit
WHERE event_type = "push"
GROUP BY 1,2,3,4,5
