# Incidents Table
SELECT
  source,
  JSON_EXTRACT_SCALAR(metadata, '$.id') as incident_id,
  TIMESTAMP(JSON_EXTRACT_SCALAR(metadata, '$.time_opened')) as time_created,
  TIMESTAMP(JSON_EXTRACT_SCALAR(metadata, '$.time_closed')) as time_resolved,
  JSON_EXTRACT_STRING_ARRAY(metadata, '$.root_causes') as root_cause,
FROM four_keys.events_raw
WHERE event_type LIKE "issue%"
;
