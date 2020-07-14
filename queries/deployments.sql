CREATE TEMP FUNCTION json2array(json STRING)
RETURNS ARRAY<STRING>
LANGUAGE js AS """
  return JSON.parse(json).map(x=>JSON.stringify(x));
"""; 

SELECT 
deploy_id, 
time_created, 
ARRAY_AGG(DISTINCT JSON_EXTRACT_SCALAR(changes, "$.id")) changes 
FROM
( 
	SELECT 
	deploy_id, 
	deploys.time_created 
	time_created, 
	change_metadata, 
	json2array(JSON_EXTRACT(change_metadata, "$.commits")) array_commits 
	FROM (
			SELECT 
			id as deploy_id, 
			time_created, 
			IF(source = "cloud_build", 
			   JSON_EXTRACT_SCALAR(metadata, "$.substitutions.COMMIT_SHA"),
			   JSON_EXTRACT_SCALAR(metadata, "$.deployment.sha")) as main_commit 
			FROM four_keys.events_raw 
			WHERE (source = "cloud_build" AND JSON_EXTRACT_SCALAR(metadata, "$.status") = "SUCCESS") 
			OR (source LIKE "github%" and event_type = "deployment") 
			) deploys 
		JOIN (
			SELECT 
			id, 
			metadata as change_metadata 
			FROM four_keys.events_raw) changes on deploys.main_commit = changes.id
) d, d.array_commits changes 
GROUP BY 1,2;
