data "google_project" "project" {
  project_id = var.project_id
}

locals {
  cloud_build_service_account = "${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
  event_handler_container_url = var.event_handler_container_url == "" ? format("gcr.io/%s/event-handler", var.project_id) : var.event_handler_container_url
  dashboard_container_url     = var.dashboard_container_url == "" ? format("gcr.io/%s/fourkeys-grafana-dashboard", var.project_id) : var.dashboard_container_url
  github_parser_url = var.github_parser_url == "" ? format("gcr.io/%s/github-parser", var.project_id) : var.github_parser_url
  gitlab_parser_url = var.gitlab_parser_url == "" ? format("gcr.io/%s/gitlab-parser", var.project_id) : var.gitlab_parser_url
  cloud_build_parser_url = var.cloud_build_parser_url == "" ? format("gcr.io/%s/cloud-build-parser", var.project_id) : var.cloud_build_parser_url
  tekton_parser_url = var.tekton_parser_url == "" ? format("gcr.io/%s/tekton-parser", var.project_id) : var.tekton_parser_url
  circleci_parser_url = var.circleci_parser_url == "" ? format("gcr.io/%s/circleci-parser", var.project_id) : var.circleci_parser_url
  pagerduty_parser_url = var.pagerduty_parser_url == "" ? format("gcr.io/%s/pagerduty-parser", var.project_id) : var.pagerduty_parser_url
  services = var.enable_apis ? [
    "bigquery.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
  ] : []
}
