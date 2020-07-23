# Changes Table
SELECT 
source,
id as change_id,
time_created,
event_type 
FROM four_keys.events_raw 
WHERE event_type in ("pull_request", "push", "merge_request")
GROUP BY 1,2,3,4;
