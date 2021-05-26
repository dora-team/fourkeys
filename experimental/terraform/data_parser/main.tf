resource "google_service_account" "parser_service_account" {
    account_id = var.parser_service
    display_name = "Service Account for ${var.parser_service} Parser Cloud Run Service"
}

module "parser_service" {
  source            = "../cloud_run_service"
  google_project_id = var.google_project_id
  google_region     = var.google_region
  service_name      = "${var.parser_service}-parser"
  service_account   = google_service_account.parser_service_account.email
}

resource "google_pubsub_topic" "parser_pubsub" {
  name = var.parser_service
}

resource "google_pubsub_topic_iam_member" "event_handler_pubsub_write_iam" {
  topic  = google_pubsub_topic.parser_pubsub.id
  role   = "roles/editor"
  member = "serviceAccount:${var.event_handler_service_account_email}"
}

resource "google_project_iam_member" "parser_bq_project_access" {
  role   = "roles/bigquery.user"
  member = "serviceAccount:${google_service_account.parser_service_account.email}"
}

resource "google_bigquery_dataset_iam_member" "parser_bq_dataset_access" {
  dataset_id = var.bq_dataset
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.parser_service_account.email}"
}

resource "google_service_account" "pubsub_cloudrun_invoker" {
  account_id   = "${var.parser_service}-cloudrun-invoker"
  display_name = "Service Account for PubSub --> Cloud Run"
}

resource "google_project_iam_member" "pubsub_cloudrun_invoker_iam" {
  member = "serviceAccount:${google_service_account.pubsub_cloudrun_invoker.email}"
  role   = "roles/run.invoker"
}

resource "google_pubsub_subscription" "parser_subscription" {
  name  = "${var.parser_service}-subscription"
  topic = google_pubsub_topic.parser_pubsub.id

  push_config {
    push_endpoint = module.parser_service.cloud_run_endpoint

    oidc_token {
      service_account_email = google_service_account.pubsub_cloudrun_invoker.email
    }

  }

}
