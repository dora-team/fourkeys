# Events table

SELECT raw.id,
       CASE
         WHEN source LIKE 'github%' OR (source LIKE 'gitlab%' AND REGEXP_CONTAINS(LOWER(metadata), r'repository'))
           THEN JSON_EXTRACT_SCALAR(metadata, '$.repository.name')
         WHEN source LIKE 'gitlab%' THEN JSON_EXTRACT_SCALAR(metadata, '$.project.name')
       END AS repo_name,
       raw.event_type,
       raw.time_created,
       raw.metadata,
       enr.enriched_metadata,
       raw.signature,
       raw.msg_id,
       raw.source
FROM four_keys.events_raw raw
LEFT JOIN four_keys.events_enriched enr
    ON raw.signature = enr.events_raw_signature
