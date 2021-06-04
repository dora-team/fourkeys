terraform {
  required_version = ">= 0.15"
  required_providers {
      google = {
          version = "~> 3.70.0"
      }
  }
}

data "google_project" "project" {
}

resource "google_project_service" "run_api" {
  service = "run.googleapis.com"
  disable_dependent_services=true
}

resource "google_project_service" "bq_api" {
  service = "bigquery.googleapis.com"
  disable_dependent_services=true
}

resource "google_project_service" "bq_dt_api" {
  service = "bigquerydatatransfer.googleapis.com"
  disable_dependent_services=true
}

resource "google_project_service" "sm_api" {
  service = "secretmanager.googleapis.com"
  disable_dependent_services=true
}

resource "google_service_account" "fourkeys_service_account" {
  account_id   = "event-handler"
  display_name = "Service Account for Four Keys resources"
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
      service_account_name = google_service_account.fourkeys_service_account.email
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

resource "google_cloud_run_service_iam_binding" "noauth" {
  location = var.google_region
  project  = var.google_project_id
  service  = "event-handler"

  role    = "roles/run.invoker"
  members = ["allUsers"]
  depends_on = [google_cloud_run_service.event_handler]
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
  member    = "serviceAccount:${google_service_account.fourkeys_service_account.email}"
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

resource "google_service_account" "parser_service_account" {
    account_id = "parser-service"
    display_name = "Service Account for data parser Cloud Run services"
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

module "data_parser_service" {
    for_each = toset(var.parsers)
    source = "./data_parser"
    parser_service_name = each.key
    google_project_id = var.google_project_id
    google_region = var.google_region
    fourkeys_service_account_email = google_service_account.fourkeys_service_account.email

    depends_on = [
        google_project_service.run_api
    ]
}
