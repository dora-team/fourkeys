SELECT
  day,
  IFNULL(ANY_VALUE(med_time_to_change), 0) AS median_time_to_change, # Hours
FROM (
  SELECT
    c.change_id,
    TIMESTAMP_TRUNC(c.time_created, DAY) AS day,
    PERCENTILE_CONT(
      # Ignore negative durations (status changes in wrong order)
      IF(TIMESTAMP_DIFF(d.time_created, c.time_created, MINUTE) > 0, TIMESTAMP_DIFF(d.time_created, c.time_created, MINUTE), NULL),
      0.5) # Median
      OVER (PARTITION BY TIMESTAMP_TRUNC(c.time_created, DAY)) AS med_time_to_change, # Minutes
  FROM 
  (
    SELECT 
      change_id, 
      time_created 
    FROM four_keys.changes 
    WHERE status = 'Done'
  ) d 
  JOIN 
  (
    SELECT 
      change_id, 
      time_created 
    FROM four_keys.changes 
    WHERE status = 'Code complete'
  ) c 
  ON d.change_id = c.change_id
)
GROUP BY day ORDER BY day DESC;
