resource "google_project_service" "bq_api" {
  service = "bigquery.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "bq_dt_api" {
  service = "bigquerydatatransfer.googleapis.com"
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

resource "google_bigquery_table" "bq_tables_derived" {
  for_each            = toset(["changes", "deployments", "incidents"])
  dataset_id          = google_bigquery_dataset.four_keys.dataset_id
  table_id            = each.key
  deletion_protection = false
}

# resource "google_bigquery_data_transfer_config" "scheduled_query" {

#   for_each = toset(["changes", "deployments", "incidents"])

#   display_name           = "four_keys_${each.key}"
#   data_source_id         = "scheduled_query"
#   schedule               = "every 24 hours"
#   destination_dataset_id = google_bigquery_dataset.four_keys.dataset_id
#   location               = var.bigquery_region
#   params = {
#     destination_table_name_template = each.key
#     write_disposition               = "WRITE_TRUNCATE"
#     query                           = file("../../queries/${each.key}.sql")
#   }
#   service_account_name = google_service_account.fourkeys_service_account.email
#   depends_on = [google_project_service.bq_dt_api, google_bigquery_table.bq_table_events_raw, google_bigquery_table.bq_tables_derived]
# }

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