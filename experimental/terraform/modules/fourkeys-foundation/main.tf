# Data and Local variables
data "google_project" "project" {
  project_id = var.project_id
}

locals {
  cloud_build_service_account = "${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

## Services
resource "google_project_service" "cloud_build" {
  project            = var.project_id
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_run" {
  project            = var.project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secret_manager" {
  project            = var.project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# Service Accounts and IAM

resource "google_service_account" "fourkeys" {
  project      = var.project_id
  account_id   = "fourkeys"
  display_name = "Service Account for Four Keys resources"
}

resource "google_project_iam_member" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${local.cloud_build_service_account}"
  depends_on = [
    google_project_service.cloud_build
  ]
}

resource "google_project_iam_member" "bigquery_user" {
  project = var.project_id
  role    = "roles/bigquery.user"
  member  = "serviceAccount:${google_service_account.fourkeys.email}"
  depends_on = [
    google_service_account.fourkeys
  ]
}

resource "google_project_iam_member" "cloud_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.fourkeys.email}"
  depends_on = [
    google_service_account.fourkeys
  ]
}

# Event handler resources

module "gcloud_build_event_handler" {
  source                 = "terraform-google-modules/gcloud/google"
  version                = "~> 2.0"
  create_cmd_entrypoint  = "gcloud"
  create_cmd_body        = "builds submit ${path.module}/files/event_handler --tag=gcr.io/${var.project_id}/event-handler --project=${var.project_id}"
  destroy_cmd_entrypoint = "gcloud"
  destroy_cmd_body       = "container images delete gcr.io/${var.project_id}/event-handler --quiet"
  module_depends_on      = [google_project_service.cloud_build]
}

resource "google_cloud_run_service" "event_handler" {
  name     = "event-handler"
  project  = var.project_id
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/event-handler"
        env {
          name  = data.google_project.project.name
          value = var.project_id
        }
      }
      service_account_name = google_service_account.fourkeys.email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true

  depends_on = [google_project_service.cloud_run, module.gcloud_build_event_handler]
}
resource "google_cloud_run_service_iam_binding" "noauth" {
  location   = var.region
  project    = var.project_id
  service    = "event-handler"
  role       = "roles/run.invoker"
  members    = ["allUsers"]
  depends_on = [google_cloud_run_service.event_handler]
}

resource "google_secret_manager_secret" "event_handler" {
  project   = var.project_id
  secret_id = "event-handler"
  replication {
    automatic = true
  }
  depends_on = [google_project_service.secret_manager]
}

resource "random_id" "event_handler_random_value" {
  byte_length = "20"
}

resource "google_secret_manager_secret_version" "event_handler" {
  secret      = google_secret_manager_secret.event_handler.id
  secret_data = random_id.event_handler_random_value.hex
  depends_on  = [google_secret_manager_secret.event_handler]
}

resource "google_secret_manager_secret_iam_member" "event_handler" {
  project    = var.project_id
  secret_id  = google_secret_manager_secret.event_handler.id
  role       = "roles/secretmanager.secretAccessor"
  member     = "serviceAccount:${google_service_account.fourkeys.email}"
  depends_on = [google_secret_manager_secret.event_handler]
}
