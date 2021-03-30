terraform {
  required_version = ">= 0.14"
}

resource "google_project_service" "run_api" {
  service = "run.googleapis.com"
}

resource "google_project_service" "bq_api" {
  service = "bigquery.googleapis.com"
}

module "cloud_run_service" {
  source            = "./cloud_run_service"
  google_project_id = var.google_project_id
  google_region     = var.google_region
  service_name      = "event-handler"

  depends_on = [
    google_project_service.run_api,
  ]

}

resource "google_bigquery_dataset" "four_keys" {
  dataset_id = "four_keys"
}

# TODO: these table creation statements might not be necessary.
# When scheduled queries are implemented, try removing this.
# (see https://github.com/GoogleCloudPlatform/fourkeys/pull/90#discussion_r604320593)
resource "google_bigquery_table" "bq_table" {
  for_each = toset(["events_raw","changes","deployments","incidents"])
  dataset_id = google_bigquery_dataset.four_keys.dataset_id
  table_id = each.key
  schema = file("../../setup/${each.key}_schema.json")
}