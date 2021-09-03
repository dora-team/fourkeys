# Data and Local variables
data "google_project" "project" {
  project_id = var.project_id
}

locals {
  cloud_build_service_account = "${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

# Service Accounts
resource "google_service_account" "fourkeys" {
  project      = var.project_id
  account_id   = "fourkeys"
  display_name = "Service Account for Four Keys resources"
}

resource "google_project_iam_member" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${local.cloud_build_service_account}"
}


# Services and API's
resource "google_project_service" "container_registry" {
  project = var.project_id
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service" "cloud_build" {
  project = var.project_id
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service" "cloud_run" {
  project = var.project_id
  service = "run.googleapis.com"
}
