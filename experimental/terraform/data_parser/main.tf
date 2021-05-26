resource "google_service_account" "parser_service_account" {
    account_id = var.parser_service
    display_name = "Service Account for ${var.parser_service} Parser Cloud Run Service"
}

resource "google_cloud_run_service" "parser_service" {
  name     = var.parser_service
  location = var.google_region

  template {
    spec {
      containers {
        image = "gcr.io/${var.google_project_id}/${var.parser_service}-parser"
        env {
          name  = "PROJECT_NAME"
          value = var.google_project_id
        }
      }
      service_account_name = google_service_account.parser_service_account.email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true

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
    push_endpoint = google_cloud_run_service.parser_service.status[0]["url"]

    oidc_token {
      service_account_email = google_service_account.pubsub_cloudrun_invoker.email
    }

  }

}
