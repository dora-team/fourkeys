data "google_project" "project" {
  project_id = var.project_id
}

locals {
  cloud_build_service_account = "${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
  event_handler_container_url = var.event_handler_container_url == "" ? format("%s-docker.pkg.dev/%s/event-handler/handler", var.region, var.project_id) : var.event_handler_container_url
  dashboard_container_url     = var.dashboard_container_url == "" ? format("%s-docker.pkg.dev/%s/dashboard/grafana", var.region, var.project_id) : var.dashboard_container_url
  github_parser_url           = var.github_parser_url == "" ? format("%s-docker.pkg.dev/%s/github-parser/parser", var.region, var.project_id) : var.github_parser_url
  gitlab_parser_url           = var.gitlab_parser_url == "" ? format("%s-docker.pkg.dev/%s/gitlab-parser/parser", var.region, var.project_id) : var.gitlab_parser_url
  cloud_build_parser_url      = var.cloud_build_parser_url == "" ? format("%s-docker.pkg.dev/%s/cloud-build-parser/parser", var.region, var.project_id) : var.cloud_build_parser_url
  tekton_parser_url           = var.tekton_parser_url == "" ? format("%s-docker.pkg.dev/%s/tekton-parser/parser", var.region, var.project_id) : var.tekton_parser_url
  circleci_parser_url         = var.circleci_parser_url == "" ? format("%s-docker.pkg.dev/%s/circleci-parser/parser", var.region, var.project_id) : var.circleci_parser_url
  pagerduty_parser_url        = var.pagerduty_parser_url == "" ? format("%s-docker.pkg.dev/%s/pagerduty-parser/parser", var.region, var.project_id) : var.pagerduty_parser_url
  services = var.enable_apis ? [
    "bigquery.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
  ] : []
}
