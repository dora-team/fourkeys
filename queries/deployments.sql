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
    (# Cloud Build pipeline
      SELECT
      ANY_VALUE(source) as source,
      ANY_VALUE(id) as deploy_id,
      ANY_VALUE(time_created) as time_created,
      JSON_EXTRACT_SCALAR(metadata, '$.substitutions.COMMIT_SHA') as main_commit
      FROM four_keys.events_raw
      WHERE source = "cloud_build"
      AND JSON_EXTRACT_SCALAR(metadata, '$.status') = "SUCCESS"
      AND JSON_EXTRACT_SCALAR(metadata, '$.substitutions.BRANCH_NAME') IN ('master', 'main')
      GROUP BY main_commit
    )
  ) deploys
  JOIN
    (SELECT
    id,
    metadata as change_metadata
    FROM four_keys.events_raw)
    changes on (
        changes.id = deploys.main_commit
      )) d, d.array_commits changes
GROUP BY 1,2,3
;
