# events table
SELECT raw.id,
       raw.event_type,
       raw.time_created,
       raw.metadata,
       enr.enriched_metadata,
       raw.signature,
       raw.msg_id,
       raw.source
FROM four_keys.events_raw raw
JOIN four_keys.events_enriched enr
    ON raw.signature = enr.events_raw_signature
