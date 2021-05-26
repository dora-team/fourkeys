terraform {
  required_version = ">= 0.14"
  required_providers {
      google = {
          version = "~> 3.69.0"
      }
  }
}

data "google_project" "project" {
}

resource "google_project_service" "run_api" {
  service = "run.googleapis.com"
}

resource "google_project_service" "bq_api" {
  service = "bigquery.googleapis.com"
}

resource "google_project_service" "bq_dt_api" {
  service = "bigquerydatatransfer.googleapis.com"
}

resource "google_project_service" "sm_api" {
  service = "secretmanager.googleapis.com"
}

resource "google_service_account" "event_handler_service_account" {
  account_id   = "event-handler"
  display_name = "Service Account for Event Handler Cloud Run Service"
}

resource "google_cloud_run_service_iam_binding" "noauth" {
  location = var.google_region
  project  = var.google_project_id
  service  = google_cloud_run_service.event_handler.name

  role    = "roles/run.invoker"
  members = ["allUsers"]
}

resource "google_cloud_run_service" "event_handler" {
  name     = "event-handler"
  location = var.google_region

  template {
    spec {
      containers {
        image = "gcr.io/${var.google_project_id}/event-handler"
        env {
          name  = "PROJECT_NAME"
          value = var.google_project_id
        }
      }
      service_account_name = google_service_account.event_handler_service_account.email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true

  depends_on = [
    google_project_service.run_api,
  ]

}

resource "google_secret_manager_secret" "event-handler-secret" {
  secret_id = "event-handler"
  replication {
    automatic = true
  }
  depends_on = [google_project_service.sm_api]
}

resource "random_id" "event-handler-random-value" {
  byte_length = "20"
}

resource "google_secret_manager_secret_version" "event-handler-secret-version" {
  secret      = google_secret_manager_secret.event-handler-secret.id
  secret_data = random_id.event-handler-random-value.hex
}

resource "google_secret_manager_secret_iam_member" "event-handler" {
  secret_id = google_secret_manager_secret.event-handler-secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.event_handler_service_account.email}"
}

resource "google_bigquery_dataset" "four_keys" {
  dataset_id = "four_keys"
  location   = var.bigquery_region
}

resource "google_bigquery_table" "bq_table_events_raw" {
  dataset_id = google_bigquery_dataset.four_keys.dataset_id
  table_id   = "events_raw"
  schema     = file("../../setup/events_raw_schema.json")
}

resource "google_bigquery_table" "bq_tables_derived" {
  for_each   = toset(["changes", "deployments", "incidents"])
  dataset_id = google_bigquery_dataset.four_keys.dataset_id
  table_id   = each.key
}

resource "google_bigquery_data_transfer_config" "scheduled_query" {

  for_each = toset(["changes", "deployments", "incidents"])

  display_name           = "four_keys_${each.key}"
  data_source_id         = "scheduled_query"
  schedule               = "every 24 hours"
  destination_dataset_id = google_bigquery_dataset.four_keys.dataset_id
  location               = var.bigquery_region
  params = {
    destination_table_name_template = each.key
    write_disposition               = "WRITE_TRUNCATE"
    query                           = file("../../queries/${each.key}.sql")
  }
  depends_on = [google_project_service.bq_dt_api, google_bigquery_table.bq_table_events_raw, google_bigquery_table.bq_tables_derived]
}

module "data_parser_service" {
    for_each = toset(["cloud-build", "github"])
    source = "./data_parser"
    parser_service = each.key
    google_project_id = var.google_project_id
    google_region = var.google_region
    event_handler_service_account_email = google_service_account.event_handler_service_account.email
    bq_dataset = google_bigquery_dataset.four_keys.dataset_id

    depends_on = [
        google_project_service.run_api
    ]
}
