# Deployments Table
CREATE TEMP FUNCTION json2array(json STRING)
RETURNS ARRAY<STRING>
LANGUAGE js AS """
  return JSON.parse(json).map(x=>JSON.stringify(x));
"""; 

SELECT
source,
deploy_id,
time_created,
ARRAY_AGG(DISTINCT JSON_EXTRACT_SCALAR(changes, '$.id')) changes
FROM(
  SELECT 
  source,
  deploy_id,
  deploys.time_created time_created,
  change_metadata,
  json2array(JSON_EXTRACT(change_metadata, '$.commits')) array_commits
  FROM
    (
    SELECT 
    source,
    id as deploy_id,
    time_created,
    CASE WHEN source = "cloud_build" then JSON_EXTRACT_SCALAR(metadata, '$.substitutions.COMMIT_SHA')
         WHEN source like "github%" then JSON_EXTRACT_SCALAR(metadata, '$.deployment.sha')
         WHEN source like "gitlab%" then JSON_EXTRACT_SCALAR(metadata, '$.commit.id') end as main_commit
    FROM four_keys.events_raw 
    WHERE ((source = "cloud_build"
    AND JSON_EXTRACT_SCALAR(metadata, '$.status') = "SUCCESS")
    OR (source LIKE "github%" and event_type = "deployment")
    OR (source LIKE "gitlab%" and event_type = "pipeline" and JSON_EXTRACT_SCALAR(metadata, '$.object_attributes.status') = "success"))
    ) deploys
  JOIN 
    (SELECT
    id,
    metadata as change_metadata
    FROM four_keys.events_raw) 
    changes on deploys.main_commit = changes.id) d, d.array_commits changes
GROUP BY 1,2,3
;
