# Data and Local variables
data "google_project" "project" {
  project_id = var.project_id
}

locals {
  cloud_build_service_account = "${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
  services = toset([
    "cloudapis.googleapis.com",
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "containerregistry.googleapis.com"

  ])
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


# Services and API's

resource "google_project_service" "all" {
  project                    = var.project_id
  for_each                   = local.services
  service                    = each.value
  disable_dependent_services = true
}
