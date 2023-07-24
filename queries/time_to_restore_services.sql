SELECT 
  day, 
  repo_name,
  ANY_VALUE(daily_med_time_to_restore) AS daily_median_time_to_restore
FROM (
  SELECT   
    TIMESTAMP_TRUNC(time_created, DAY) AS day,
    repo_name,  
    PERCENTILE_CONT(
      TIMESTAMP_DIFF(time_resolved, time_created, MINUTE), 0.5
    ) OVER(PARTITION BY TIMESTAMP_TRUNC(time_created, DAY), repo_name) AS daily_med_time_to_restore
  FROM 
    four_keys.incidents
)
GROUP BY 
  day,
  repo_name
ORDER BY 
  day
