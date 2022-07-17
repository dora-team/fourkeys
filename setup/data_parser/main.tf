resource "google_cloud_run_service" "parser" {
  name     = "${var.parser_service_name}-parser"
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

  metadata {
    labels = { "created_by" : "fourkeys" }
  }

}

resource "google_pubsub_topic" "parser" {
  name   = var.parser_service_name
  labels = { "created_by" : "fourkeys" }
}

resource "google_pubsub_topic_iam_member" "event_handler" {
  topic  = google_pubsub_topic.parser.id
  role   = "roles/editor"
  member = "serviceAccount:${var.fourkeys_service_account_email}"
}

resource "google_pubsub_subscription" "parser" {
  name  = "${var.parser_service_name}-subscription"
  topic = google_pubsub_topic.parser.id

  push_config {
    push_endpoint = google_cloud_run_service.parser.status[0]["url"]

    oidc_token {
      service_account_email = var.fourkeys_service_account_email
    }

  }
  labels = { "created_by" : "fourkeys" }

}
