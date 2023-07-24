SELECT 
  d.repo_name AS metric,
  d.env,
  TIMESTAMP_TRUNC(d.time_created, DAY) AS day,
  IFNULL(APPROX_QUANTILES(
    IF(TIMESTAMP_DIFF(d.time_created, c.time_created, MINUTE) > 0, 
    TIMESTAMP_DIFF(d.time_created, c.time_created, MINUTE), NULL),
    100)[OFFSET(50)], 0) AS median_time_to_change
FROM four_keys.deployments d
LEFT JOIN UNNEST(d.changes) AS changes
LEFT JOIN four_keys.changes c ON changes = c.change_id
GROUP BY day, metric, env
ORDER BY day, metric, env