SELECT 
  deployment_day,
  IFNULL(incident_count, 0) as incident_count,
  IFNULL(deployment_count, 0) as deployment_count,
  IFNULL(incident_count, 0) / IFNULL(deployment_count, 0) AS change_failure_rate
FROM
  (SELECT 
    TIMESTAMP_TRUNC(time_created, DAY) AS deployment_day,
    COUNT(deploy_id) AS deployment_count
  FROM 
    four_keys.deployments
  GROUP BY 
    deployment_day) AS deploys_day
LEFT JOIN 
  (SELECT 
    TIMESTAMP_TRUNC(time_created, DAY) AS incident_day,
    COUNT(change_id) AS incident_count
  FROM 
    four_keys.incidents
  GROUP BY 
    incident_day) AS incidents_day
ON 
  deploys_day.deployment_day = incidents_day.incident_day
ORDER BY 
  deployment_day DESC;

