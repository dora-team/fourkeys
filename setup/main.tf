terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.18.0"
    }
  }
}

resource "google_project_service" "run_api" {
  project = var.google_project_id
  service = "run.googleapis.com"
}

resource "google_service_account" "fourkeys" {
  account_id   = "fourkeys"
  display_name = "Service Account for Four Keys resources"
}
