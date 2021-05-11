terraform {
  required_version = ">= 0.14"
}

resource "google_project_service" "run_api" {
  service = "run.googleapis.com"
}

resource "google_project_service" "bq_api" {
  service = "bigquery.googleapis.com"
}

resource "google_project_service" "sm_api" {
  service = "secretmanager.googleapis.com"
}

module "event_handler_service" {
  source            = "./cloud_run_service"
  google_project_id = var.google_project_id
  google_region     = var.google_region
  service_name      = "event-handler"
  service_account   = google_service_account.event_handler_service_account.email

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
  for_each   = toset(["events_raw", "changes", "deployments", "incidents"])
  dataset_id = google_bigquery_dataset.four_keys.dataset_id
  table_id   = each.key
  schema     = file("../../setup/${each.key}_schema.json")
}

resource "random_id" "event-handler-random-value" {
  byte_length = "20"
}

resource "google_secret_manager_secret" "event-handler-secret" {
  secret_id = "event-handler"
  replication {
    automatic = true
  }
  depends_on = [google_project_service.sm_api]
}

resource "google_secret_manager_secret_version" "event-handler-secret-version" {
  secret      = google_secret_manager_secret.event-handler-secret.id
  secret_data = random_id.event-handler-random-value.hex
}

resource "google_service_account" "event_handler_service_account" {
  account_id   = "event-handler"
  display_name = "Service Account for Event Handler Cloud Run Service"
}

resource "google_service_account" "github_parser_service_account" {
  account_id   = "github-parser"
  display_name = "Service Account for GitHub Parser Cloud Run Service"
}

resource "google_secret_manager_secret_iam_member" "event-handler" {
  secret_id = google_secret_manager_secret.event-handler-secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.event_handler_service_account.email}"
}

module "github_parser_service" {
  source            = "./cloud_run_service"
  google_project_id = var.google_project_id
  google_region     = var.google_region
  service_name      = "github-parser"
  service_account   = google_service_account.github_parser_service_account.email

  depends_on = [
    google_project_service.run_api,
  ]

}

resource "google_pubsub_topic" "github" {
  name = "GitHub-Hookshot"
}

resource "google_pubsub_topic_iam_member" "event_handler_pubsub_write_iam" {
  topic  = google_pubsub_topic.github.id
  role   = "roles/editor"
  member = "serviceAccount:${google_service_account.event_handler_service_account.email}"
}

resource "google_project_iam_member" "github_parser_bq_project_access" {
  role   = "roles/bigquery.user"
  member = "serviceAccount:${google_service_account.github_parser_service_account.email}"
}

resource "google_bigquery_dataset_iam_member" "github_parser_bq_dataset_access" {
  dataset_id = "four_keys"
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.github_parser_service_account.email}"
}

resource "google_service_account" "pubsub_cloudrun_invoker" {
  account_id   = "pubsub-cloudrun-invoker"
  display_name = "Service Account for PubSub --> Cloud Run"
}

resource "google_project_iam_member" "pubsub_cloudrun_invoker_iam" {
  member = "serviceAccount:${google_service_account.pubsub_cloudrun_invoker.email}"
  role   = "roles/run.invoker"
}

resource "google_pubsub_subscription" "github_subscription" {
  name  = "github-subscription"
  topic = google_pubsub_topic.github.id

  push_config {
    push_endpoint = module.github_parser_service.cloud_run_endpoint

    oidc_token {
      service_account_email = google_service_account.pubsub_cloudrun_invoker.email
    }

  }

}