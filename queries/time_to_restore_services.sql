SELECT 
  day, 
  change_id,
  ANY_VALUE(daily_med_time_to_restore) AS daily_median_time_to_restore
FROM (
  SELECT   
    TIMESTAMP_TRUNC(c1.time_created, DAY) AS day,
    c1.change_id,  
    PERCENTILE_CONT(
      TIMESTAMP_DIFF(c2.time_created, c1.time_created, MINUTE), 0.5
    ) OVER(PARTITION BY TIMESTAMP_TRUNC(c1.time_created, DAY), c1.change_id) AS daily_med_time_to_restore
  FROM 
    four_keys.changes c1
  JOIN 
    four_keys.changes c2
  ON 
    c1.change_id = c2.change_id
  WHERE 
    c1.status = 'To Do'
  AND 
    c2.status = 'Done'
  AND 
    c1.event_type = 'Task'
  AND 
    c2.event_type = 'Task'
  AND 
    c2.time_created > c1.time_created
)
GROUP BY 
  day,
  change_id
ORDER BY 
  day
