# this file contains global config and APIs.
# for resources, see `resource_*.tf` files

terraform {
  required_version = ">= 0.14"
}

data "google_project" "project" {
}

resource "google_project_service" "run_api" {
  service = "run.googleapis.com"
}

resource "google_project_service" "bq_api" {
  service = "bigquery.googleapis.com"
}

resource "google_project_service" "bq_dt_api" {
  service = "bigquerydatatransfer.googleapis.com"
}

resource "google_project_service" "sm_api" {
  service = "secretmanager.googleapis.com"
}