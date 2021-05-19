resource "google_bigquery_dataset" "four_keys" {
  dataset_id = "four_keys"
}

# TODO remove "for_each" and hardcode
resource "google_bigquery_table" "bq_table_events_raw" {
  for_each   = toset(["events_raw"])
  dataset_id = google_bigquery_dataset.four_keys.dataset_id
  table_id   = each.key
  schema     = file("../../setup/${each.key}_schema.json")
}

resource "google_bigquery_table" "bq_tables_derived" {
  for_each   = toset(["changes", "deployments", "incidents"])
  dataset_id = google_bigquery_dataset.four_keys.dataset_id
  table_id   = each.key
}

resource "google_bigquery_data_transfer_config" "scheduled_query1" {

  for_each = toset(["changes", "deployments", "incidents"])

  display_name           = "four_keys_${each.key}"
  data_source_id         = "scheduled_query"
  schedule               = "every 24 hours"
  destination_dataset_id = google_bigquery_dataset.four_keys.dataset_id
  params = {
    destination_table_name_template = each.key
    write_disposition               = "WRITE_TRUNCATE"
    query                           = file("../../queries/${each.key}.sql")
  }
  depends_on = [google_project_service.bq_dt_api, google_bigquery_table.bq_table_events_raw, google_bigquery_table.bq_tables_derived]
}