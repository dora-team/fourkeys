# Deployments Table

WITH deploys_cloudbuild_github_gitlab AS (# Cloud Build, Github, Gitlab pipelines
      SELECT 
      source,
      id as deploy_id,
      time_created,
      CASE WHEN source = "cloud_build" then JSON_EXTRACT_SCALAR(metadata, '$.substitutions.COMMIT_SHA')
           WHEN source like "github%" then JSON_EXTRACT_SCALAR(metadata, '$.deployment.sha')
           WHEN source like "gitlab%" then JSON_EXTRACT_SCALAR(metadata, '$.commit.id') end as main_commit,
      CASE WHEN source LIKE "github%" THEN ARRAY(
                SELECT JSON_EXTRACT_SCALAR(string_element, '$')
                FROM UNNEST(JSON_EXTRACT_ARRAY(metadata, '$.deployment.additional_sha')) AS string_element)
           ELSE ARRAY<string>[] end as additional_commits
      FROM four_keys.events_raw 
      WHERE ((source = "cloud_build"
      AND JSON_EXTRACT_SCALAR(metadata, '$.status') = "SUCCESS")
      OR (source LIKE "github%" and event_type = "deployment_status" and JSON_EXTRACT_SCALAR(metadata, '$.deployment_status.state') = "success")
      OR (source LIKE "gitlab%" and event_type = "pipeline" and JSON_EXTRACT_SCALAR(metadata, '$.object_attributes.status') = "success"))
    ),
    deploys_tekton AS (# Tekton Pipelines
      SELECT
      source,
      id as deploy_id,
      time_created,
      IF(JSON_EXTRACT_SCALAR(param, '$.name') = "gitrevision", JSON_EXTRACT_SCALAR(param, '$.value'), Null) as main_commit,
      ARRAY<string>[] AS additional_commits
      FROM (
      SELECT 
      id,
      TIMESTAMP_TRUNC(time_created, second) as time_created,
      source,
      four_keys.json2array(JSON_EXTRACT(metadata, '$.data.pipelineRun.spec.params')) params
      FROM four_keys.events_raw
      WHERE event_type = "dev.tekton.event.pipelinerun.successful.v1" 
      AND metadata like "%gitrevision%") e, e.params as param
    ),
    deploys_circleci AS (# CircleCI pipelines
      SELECT
      source,
      id AS deploy_id,
      time_created,
      JSON_EXTRACT_SCALAR(metadata, '$.pipeline.vcs.revision') AS main_commit,
      ARRAY<string>[] AS additional_commits
      FROM four_keys.events_raw
      WHERE (source = "circleci" AND event_type = "workflow-completed" AND JSON_EXTRACT_SCALAR(metadata, '$.workflow.name') LIKE "%deploy%" AND JSON_EXTRACT_SCALAR(metadata, '$.workflow.status') = "success")
    ),
    deploys AS (
      SELECT * FROM
      deploys_cloudbuild_github_gitlab
      UNION ALL
      SELECT * FROM deploys_tekton
      UNION ALL
      SELECT * FROM deploys_circleci
    ),
    changes_raw AS (
      SELECT
      id,
      metadata as change_metadata
      FROM four_keys.events_raw
    ),
    deployment_changes as (
      SELECT
      source,
      deploy_id,
      deploys.time_created time_created,
      change_metadata,
      four_keys.json2array(JSON_EXTRACT(change_metadata, '$.commits')) as array_commits,
      main_commit
      FROM deploys
      JOIN
        changes_raw on (
          changes_raw.id = deploys.main_commit
          or changes_raw.id in unnest(deploys.additional_commits)
        )
    )

    SELECT 
    source,
    deploy_id,
    time_created,
    main_commit,   
    ARRAY_AGG(DISTINCT JSON_EXTRACT_SCALAR(array_commits, '$.id')) changes,    
    FROM deployment_changes
    CROSS JOIN deployment_changes.array_commits
    GROUP BY 1,2,3,4;
