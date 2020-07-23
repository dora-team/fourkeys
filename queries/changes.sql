SELECT 
id as change_id, 
time_created, 
event_type 
FROM four_keys.events_raw 
WHERE event_type in ("pull_request", "push") 
GROUP BY 1,2,3;