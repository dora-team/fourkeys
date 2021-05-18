resource "google_service_account" "github_parser_service_account" {
  account_id   = "github-parser"
  display_name = "Service Account for GitHub Parser Cloud Run Service"
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

resource "google_pubsub_topic_iam_member" "event_handler_github_pubsub_write_iam" {
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