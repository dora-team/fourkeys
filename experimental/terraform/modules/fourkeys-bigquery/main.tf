locals {
    services = var.enable_apis ? [
    "bigquery.googleapis.com"
  ] : []
}

resource "google_project_service" "bigquery_services" {
  project                    = var.project_id
  for_each                   = toset(local.services)
  service                    = each.value
  disable_on_destroy         = false
}

resource "google_project_iam_member" "parser_bq_project_access" {
  project = var.project_id
  role    = "roles/bigquery.user"
  member  = "serviceAccount:${var.fourkeys_service_account_email}"
}

resource "google_bigquery_dataset_iam_member" "parser_bq" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.four_keys.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.fourkeys_service_account_email}"
}

resource "google_project_iam_member" "parser_run_invoker" {
  project = var.project_id
  member  = "serviceAccount:${var.fourkeys_service_account_email}"
  role    = "roles/run.invoker"
}

resource "google_bigquery_dataset" "four_keys" {
  project    = var.project_id
  dataset_id = "four_keys"
  location   = var.bigquery_region
  depends_on = [
    google_project_service.bigquery_services
  ]
}

resource "google_bigquery_table" "events_raw" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.four_keys.dataset_id
  table_id            = "events_raw"
  schema              = file("${path.module}/files/events_raw_schema.json")
  deletion_protection = false
  depends_on = [
    google_project_service.bigquery_services
  ]
}

resource "google_bigquery_table" "view_changes" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.four_keys.dataset_id
  table_id   = "changes"
  view {
    query          = file("${path.module}/queries/changes.sql")
    use_legacy_sql = false
  }
  deletion_protection = false
  depends_on = [
    google_project_service.bigquery_services,
    google_bigquery_table.events_raw
  ]
}

resource "google_bigquery_routine" "func_json2array" {
  project      = var.project_id
  dataset_id   = google_bigquery_dataset.four_keys.dataset_id
  routine_id   = "json2array"
  routine_type = "SCALAR_FUNCTION"
  return_type  = "{\"typeKind\": \"ARRAY\", \"arrayElementType\": {\"typeKind\": \"STRING\"}}"
  language     = "JAVASCRIPT"
  arguments {
    name      = "json"
    data_type = "{\"typeKind\" :  \"STRING\"}"
  }
  definition_body = file("${path.module}/queries/function_json2array.js")
  depends_on = [
    google_project_service.bigquery_services
  ]
}

resource "google_bigquery_routine" "func_multiFormatParseTimestamp" {
  project    = var.project_id
  dataset_id   = google_bigquery_dataset.four_keys.dataset_id
  routine_id   = "multiFormatParseTimestamp"
  routine_type = "SCALAR_FUNCTION"
  return_type = "{\"typeKind\" :  \"TIMESTAMP\"}"
  language     = "SQL"
  arguments {
    name      = "input"
    data_type = "{\"typeKind\" :  \"STRING\"}"
  }
  definition_body = file("${path.module}/queries/function_multiFormatParseTimestamp.sql")
}

resource "google_bigquery_table" "view_deployments" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.four_keys.dataset_id
  table_id   = "deployments"
  view {
    query          = file("${path.module}/queries/deployments.sql")
    use_legacy_sql = false
  }
  deletion_protection = false
  depends_on = [
    google_project_service.bigquery_services,
    google_bigquery_table.events_raw,
    google_bigquery_routine.func_json2array
  ]
}

resource "google_bigquery_table" "view_incidents" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.four_keys.dataset_id
  table_id   = "incidents"
  view {
    query          = file("${path.module}/queries/incidents.sql")
    use_legacy_sql = false
  }
  deletion_protection = false
  depends_on = [
    google_project_service.bigquery_services,
    google_bigquery_table.events_raw,
    google_bigquery_table.view_deployments,
    google_bigquery_routine.func_multiFormatParseTimestamp
  ]
}
