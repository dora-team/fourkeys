resource "google_cloud_run_service" "parser_service" {
  name     = var.parser_service_name
  location = var.google_region

  template {
    spec {
      containers {
        image = "gcr.io/${var.google_project_id}/${var.parser_service_name}-parser"
        env {
          name  = "PROJECT_NAME"
          value = var.google_project_id
        }
      }
      service_account_name = var.fourkeys_service_account_email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true

}

resource "google_pubsub_topic" "parser_pubsub" {
  name = var.parser_service_name
}

resource "google_pubsub_topic_iam_member" "event_handler_pubsub_write_iam" {
  topic  = google_pubsub_topic.parser_pubsub.id
  role   = "roles/editor"
  member = "serviceAccount:${var.fourkeys_service_account_email}"
}

resource "google_pubsub_subscription" "parser_subscription" {
  name  = "${var.parser_service_name}-subscription"
  topic = google_pubsub_topic.parser_pubsub.id

  push_config {
    push_endpoint = google_cloud_run_service.parser_service.status[0]["url"]

    oidc_token {
      service_account_email = var.fourkeys_service_account_email
    }

  }

}
