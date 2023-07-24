SELECT 
  d.repo_name AS metric,
  d.env AS env,
  TIMESTAMP_TRUNC(d.time_created, DAY) AS day,   
  IF(COUNT(DISTINCT change_id) = 0, 0, SUM(IF(i.incident_id IS NULL, 0, 1)) / COUNT(DISTINCT deploy_id)) AS change_fail_rate 
FROM 
  four_keys.deployments d, d.changes 
LEFT JOIN 
  four_keys.changes c ON changes = c.change_id 
LEFT JOIN(
  SELECT         
    incident_id,         
    change,         
    time_resolved         
    FROM four_keys.incidents i, i.changes change
) i 
ON i.change = changes
GROUP BY 
  day, 
  d.repo_name, 
  env