# incident Table
SELECT 
  change_id,
  ANY_VALUE(source) AS source,
  ANY_VALUE(event_type) AS event_type,
  MIN(time_created) AS time_created,
  ANY_VALUE(status) AS status
FROM 
  four_keys.changes
WHERE 
  event_type = 'Bug'
GROUP BY 
  change_id;
