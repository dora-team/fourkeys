resource "google_project_service" "bq_api" {
  service                    = "bigquery.googleapis.com"
  disable_dependent_services = true
}

# The BigQuery API can take time to become interactive, so add a delay 
# before attempting to create resources
resource "time_sleep" "wait_for_bq_api" {
  depends_on = [
    google_project_service.bq_api
  ]

  create_duration = "30s" # adjust this duration as needed
}

resource "google_bigquery_dataset" "four_keys" {
  dataset_id                 = "four_keys"
  delete_contents_on_destroy = false
  location                   = var.bigquery_region
  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }
  access {
    role          = "WRITER"
    user_by_email = google_service_account.fourkeys.email
  }
  depends_on = [
    time_sleep.wait_for_bq_api
  ]
}

resource "google_bigquery_table" "events_raw" {
  dataset_id          = google_bigquery_dataset.four_keys.dataset_id
  table_id            = "events_raw"
  schema              = file("./events_raw_schema.json")
  deletion_protection = false
}

resource "google_bigquery_table" "events_enriched" {
  dataset_id          = google_bigquery_dataset.four_keys.dataset_id
  table_id            = "events_enriched"
  schema              = file("./events_enriched_schema.json")
  deletion_protection = false
}

resource "google_bigquery_table" "view_events" {
  dataset_id = google_bigquery_dataset.four_keys.dataset_id
  table_id   = "events"
  view {
    query          = file("../queries/events.sql")
    use_legacy_sql = false
  }
  deletion_protection = false
  depends_on = [
    google_bigquery_table.events_raw,
    google_bigquery_table.events_enriched,
  ]
}

resource "google_bigquery_table" "view_changes" {
  dataset_id = google_bigquery_dataset.four_keys.dataset_id
  table_id   = "changes"
  view {
    query          = file("../queries/changes.sql")
    use_legacy_sql = false
  }
  deletion_protection = false
  depends_on = [
    google_bigquery_table.events_raw
  ]
}

resource "google_bigquery_routine" "func_json2array" {
  dataset_id   = google_bigquery_dataset.four_keys.dataset_id
  routine_id   = "json2array"
  routine_type = "SCALAR_FUNCTION"
  return_type  = "{\"typeKind\": \"ARRAY\", \"arrayElementType\": {\"typeKind\": \"STRING\"}}"
  language     = "JAVASCRIPT"
  arguments {
    name      = "json"
    data_type = "{\"typeKind\" :  \"STRING\"}"
  }
  definition_body = file("../queries/function_json2array.js")
}

resource "google_bigquery_routine" "func_multiFormatParseTimestamp" {
  dataset_id   = google_bigquery_dataset.four_keys.dataset_id
  routine_id   = "multiFormatParseTimestamp"
  routine_type = "SCALAR_FUNCTION"
  return_type  = "{\"typeKind\" :  \"TIMESTAMP\"}"
  language     = "SQL"
  arguments {
    name      = "input"
    data_type = "{\"typeKind\" :  \"STRING\"}"
  }
  definition_body = file("../queries/function_multiFormatParseTimestamp.sql")
}

resource "google_bigquery_table" "view_deployments" {
  dataset_id = google_bigquery_dataset.four_keys.dataset_id
  table_id   = "deployments"
  view {
    query          = file("../queries/deployments.sql")
    use_legacy_sql = false
  }
  deletion_protection = false
  depends_on = [
    google_bigquery_table.events_raw,
    google_bigquery_routine.func_json2array
  ]
}

resource "google_bigquery_table" "view_incidents" {
  dataset_id = google_bigquery_dataset.four_keys.dataset_id
  table_id   = "incidents"
  view {
    query          = file("../queries/incidents.sql")
    use_legacy_sql = false
  }
  deletion_protection = false
  depends_on = [
    google_bigquery_table.events_raw,
    google_bigquery_table.view_deployments,
    google_bigquery_routine.func_multiFormatParseTimestamp
  ]
}

resource "google_project_iam_member" "parser_bq_project_access" {
  project = google_service_account.fourkeys.project
  role   = "roles/bigquery.user"
  member = "serviceAccount:${google_service_account.fourkeys.email}"
}

resource "google_bigquery_dataset_iam_member" "parser_bq" {
  project = google_service_account.fourkeys.project
  dataset_id = google_bigquery_dataset.four_keys.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.fourkeys.email}"
}


resource "google_project_iam_member" "parser_run_invoker" {
  project = google_service_account.fourkeys.project
  member  = "serviceAccount:${google_service_account.fourkeys.email}"
  role    = "roles/run.invoker"
}