resource "google_project_service" "bq_api" {
  service                    = "bigquery.googleapis.com"
  disable_dependent_services = true
}

resource "google_bigquery_dataset" "four_keys" {
  dataset_id = "four_keys"
  location   = var.bigquery_region
  depends_on = [
    google_project_service.bq_api
  ]
}

resource "google_bigquery_table" "bq_table_events_raw" {
  dataset_id          = google_bigquery_dataset.four_keys.dataset_id
  table_id            = "events_raw"
  schema              = file("../../setup/events_raw_schema.json")
  deletion_protection = false
}

resource "google_bigquery_table" "bq_view_changes" {
  dataset_id = google_bigquery_dataset.four_keys.dataset_id
  table_id   = "changes"
  view {
    query          = file("../../queries/changes.sql")
    use_legacy_sql = false
  }
  deletion_protection = false
  depends_on = [
    google_bigquery_table.bq_table_events_raw
  ]
}

resource "google_bigquery_routine" "bq_func_json2array" {
  dataset_id   = google_bigquery_dataset.four_keys.dataset_id
  routine_id   = "json2array"
  routine_type = "SCALAR_FUNCTION"
  return_type  = "{\"typeKind\": \"ARRAY\", \"arrayElementType\": {\"typeKind\": \"STRING\"}}"
  language     = "JAVASCRIPT"
  arguments {
    name      = "json"
    data_type = "{\"typeKind\" :  \"STRING\"}"
  }
  definition_body = "return JSON.parse(json).map(x=>JSON.stringify(x));"
}

resource "google_bigquery_table" "bq_view_deployments" {
  dataset_id = google_bigquery_dataset.four_keys.dataset_id
  table_id   = "deployments"
  view {
    query          = file("../../queries/deployments.sql")
    use_legacy_sql = false
  }
  deletion_protection = false
  depends_on = [
    google_bigquery_table.bq_table_events_raw,
    google_bigquery_routine.bq_func_json2array
  ]
}

resource "google_bigquery_table" "bq_view_incidents" {
  dataset_id = google_bigquery_dataset.four_keys.dataset_id
  table_id   = "incidents"
  view {
    query          = file("../../queries/incidents.sql")
    use_legacy_sql = false
  }
  deletion_protection = false
  depends_on = [
    google_bigquery_table.bq_table_events_raw,
    google_bigquery_table.bq_view_deployments
  ]
}

resource "google_project_iam_member" "parser_bq_project_access" {
  role   = "roles/bigquery.user"
  member = "serviceAccount:${google_service_account.fourkeys_service_account.email}"
}

resource "google_bigquery_dataset_iam_member" "parser_bq_dataset_access" {
  dataset_id = google_bigquery_dataset.four_keys.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.fourkeys_service_account.email}"
}

resource "google_project_iam_member" "parser_service_account_run_invoker" {
  member = "serviceAccount:${google_service_account.fourkeys_service_account.email}"
  role   = "roles/run.invoker"
}