# Incidents Table
SELECT
source,
incident_id,
MIN(IF(root.time_created < issue.time_created, root.time_created, issue.time_created)) as time_created,
MAX(time_resolved) as time_resolved,
ARRAY_AGG(root_cause IGNORE NULLS) changes,
FROM
(
SELECT DISTINCT
source,
repo_name,
ARRAY(SELECT REGEXP_EXTRACT(JSON_EXTRACT_SCALAR(labels_json_array, '$.name'),'^component:([a-zA-Z0-9-.]+$)')
      FROM UNNEST(JSON_EXTRACT_ARRAY(metadata, '$.issue.labels')) labels_json_array
      WHERE JSON_EXTRACT_SCALAR(labels_json_array, '$.name') LIKE 'component:%')[SAFE_OFFSET(0)] as component,
CASE WHEN source LIKE "github%" THEN JSON_EXTRACT_SCALAR(metadata, '$.issue.number')
     WHEN source LIKE "gitlab%" AND event_type = "note" THEN JSON_EXTRACT_SCALAR(metadata, '$.object_attributes.noteable_id')
     WHEN source LIKE "gitlab%" AND event_type = "issue" THEN JSON_EXTRACT_SCALAR(metadata, '$.object_attributes.id')
     WHEN source LIKE "pagerduty%" THEN JSON_EXTRACT_SCALAR(metadata, '$.event.data.id')
     END AS incident_id,
CASE WHEN source LIKE "github%" THEN TIMESTAMP(JSON_EXTRACT_SCALAR(metadata, '$.issue.created_at'))
     WHEN source LIKE "gitlab%" THEN four_keys.multiFormatParseTimestamp(JSON_EXTRACT_SCALAR(metadata, '$.object_attributes.created_at'))
     WHEN source LIKE "pagerduty%" THEN TIMESTAMP(JSON_EXTRACT_SCALAR(metadata, '$.event.occurred_at'))
     END AS time_created,
CASE WHEN source LIKE "github%" THEN TIMESTAMP(JSON_EXTRACT_SCALAR(metadata, '$.issue.closed_at'))
     WHEN source LIKE "gitlab%" THEN four_keys.multiFormatParseTimestamp(JSON_EXTRACT_SCALAR(metadata, '$.object_attributes.closed_at'))
     WHEN source LIKE "pagerduty%" THEN TIMESTAMP(JSON_EXTRACT_SCALAR(metadata, '$.event.occurred_at'))
     END AS time_resolved,
REGEXP_EXTRACT(metadata, r"root cause: ([[:alnum:]]*)") as root_cause,
CASE WHEN source LIKE "github%" THEN REGEXP_CONTAINS(JSON_EXTRACT(metadata, '$.issue.labels'), '"name":"incident"')
     WHEN source LIKE "gitlab%" THEN REGEXP_CONTAINS(JSON_EXTRACT(metadata, '$.object_attributes.labels'), '"title":"Incident"')
     WHEN source LIKE "pagerduty%" THEN TRUE # All Pager Duty events are incident-related
     END AS bug,
FROM four_keys.events
WHERE event_type LIKE "issue%" OR event_type LIKE "incident%" OR (event_type = "note" and JSON_EXTRACT_SCALAR(metadata, '$.object_attributes.noteable_type') = 'Issue')
) issue
LEFT JOIN (SELECT time_created, changes FROM four_keys.deployments d, d.changes) root on root.changes = root_cause
WHERE issue.time_resolved is not NULL 
GROUP BY 1,2
HAVING max(bug) is True
;