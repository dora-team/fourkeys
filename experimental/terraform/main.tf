terraform {
  required_version = ">= 0.15"
  required_providers {
    google = {
      version = "~> 3.70.0"
    }
  }
}

resource "google_project_service" "run_api" {
  service = "run.googleapis.com"
}

resource "google_service_account" "fourkeys_service_account" {
  account_id   = "fourkeys"
  display_name = "Service Account for Four Keys resources"
}
