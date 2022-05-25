data "google_project" "project" {
  project_id = var.project_id
}

locals {
  services = var.enable_apis ? [
    "run.googleapis.com"
  ] : []
}

resource "google_project_service" "data_source_services" {
  project                    = var.project_id
  for_each                   = toset(local.services)
  service                    = each.value
  disable_on_destroy         = false
}

resource "google_cloud_run_service" "github_parser" {
  project  = var.project_id
  name     = "fourkeys-github-parser"
  location = var.region

  template {
    spec {
      containers {
        image = var.parser_container_url
        env {
          name  = "PROJECT_NAME"
          value = var.project_id
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
  depends_on = [
    google_project_service.data_source_services
  ]
}

resource "google_pubsub_topic" "github" {
  project = var.project_id
  name    = "github"
}

resource "google_pubsub_topic_iam_member" "service_account_editor" {
  project = var.project_id
  topic   = google_pubsub_topic.github.id
  role    = "roles/editor"
  member  = "serviceAccount:${var.fourkeys_service_account_email}"
}

resource "google_pubsub_subscription" "github" {
  project = var.project_id
  name    = "github"
  topic   = google_pubsub_topic.github.id

  push_config {
    push_endpoint = google_cloud_run_service.github_parser.status[0]["url"]

    oidc_token {
      service_account_email = var.fourkeys_service_account_email
    }
  }
}

resource "google_project_iam_member" "pubsub_service_account_token_creator" {
  project = var.project_id
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
  role    = "roles/iam.serviceAccountTokenCreator"
}