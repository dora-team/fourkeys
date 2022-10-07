data "google_project" "project" {
  project_id = var.project_id
}

locals {
  services = var.enable_apis ? [
    "run.googleapis.com",
    "secretmanager.googleapis.com"
  ] : []
}

resource "google_project_service" "data_source_services" {
  project                    = var.project_id
  for_each                   = toset(local.services)
  service                    = each.value
  disable_on_destroy         = false
}

resource "google_cloud_run_service" "prometheus_parser" {
  project  = var.project_id
  name     = "fourkeys-prometheus-parser"
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

resource "google_pubsub_topic" "prometheus" {
  project = var.project_id
  name    = "prometheus"
}

resource "google_pubsub_topic_iam_member" "service_account_editor" {
  project = var.project_id
  topic   = google_pubsub_topic.prometheus.id
  role    = "roles/pubsub.editor"
  member  = "serviceAccount:${var.fourkeys_service_account_email}"
}

resource "google_pubsub_subscription" "prometheus" {
  project = var.project_id
  name    = "prometheus"
  topic   = google_pubsub_topic.prometheus.id

  push_config {
    push_endpoint = google_cloud_run_service.prometheus_parser.status[0]["url"]

    oidc_token {
      service_account_email = var.fourkeys_service_account_email
    }
  }
}
# This IAM role grant is for projects created before April 8, 2021. See: https://cloud.google.com/pubsub/docs/push
resource "google_project_iam_member" "pubsub_service_account_token_creator" {
  project = var.project_id
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
  role    = "roles/iam.serviceAccountTokenCreator"
}

resource "random_password" "prometheus_alertmanager_token" {
  length  = 32
  special = true

  keepers = {
    cloud_run_name = google_cloud_run_service.prometheus_parser.name
  }
}

resource "google_secret_manager_secret" "prometheus_alertmanager_token" {
  secret_id = "fourkeys_prometheus_secret"

  labels = { "created_by" : "fourkeys" }

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  depends_on = [
    google_project_service.data_source_services
  ]
}

resource "google_secret_manager_secret_version" "prometheus_alertmanager_token" {
  secret = google_secret_manager_secret.prometheus_alertmanager_token.id

  secret_data = random_password.prometheus_alertmanager_token.result
}


resource "google_secret_manager_secret_iam_member" "prometheus_alertmanager_token" {
  project = var.project_id

  secret_id = google_secret_manager_secret.prometheus_alertmanager_token.id
  role = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${var.fourkeys_service_account_email}"
}