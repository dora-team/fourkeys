data "google_project" "project" {
  project_id = var.project_id
}

locals {
  event_handler_container_url = var.enable_build_images ? format("gcr.io/%s/event-handler", var.project_id) : var.event_handler_container_url
  dashboard_container_url     = var.enable_build_images ? format("gcr.io/%s/fourkeys-grafana-dashboard", var.project_id) : var.dashboard_container_url
  parser_container_urls = var.enable_build_images ? {
    "github"      = format("gcr.io/%s/github-parser", var.project_id)
    "gitlab"      = format("gcr.io/%s/gitlab-parser", var.project_id)
    "cloud-build" = format("gcr.io/%s/cloud-build-parser", var.project_id)
    "tekton"      = format("gcr.io/%s/tekton-parser", var.project_id)
  } : var.parser_container_urls
}

module "fourkeys_images" {
  source      = "../fourkeys-images"
  count       = var.enable_build_images ? 1 : 0
  project_id  = var.project_id
  enable_apis = var.enable_apis
  parsers     = var.parsers
}

resource "google_project_iam_member" "pubsub_service_account_token_creator" {
  project = var.project_id
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
  role    = "roles/iam.serviceAccountTokenCreator"
}

module "foundation" {
  source                      = "../fourkeys-foundation"
  project_id                  = var.project_id
  event_handler_container_url = local.event_handler_container_url
  enable_apis                 = var.enable_apis
  depends_on = [
    module.fourkeys_images
  ]
}
output "event_handler_endpoint" {
  value = module.foundation.event_handler_endpoint
}

output "event_handler_secret" {
  value     = module.foundation.event_handler_secret
  sensitive = true
}

output "dashboard_endpoint" {
  value = module.dashboard.dashboard_endpoint
}

module "bigquery" {
  source                         = "../fourkeys-bigquery"
  project_id                     = var.project_id
  bigquery_region                = var.region
  fourkeys_service_account_email = module.foundation.fourkeys_service_account_email
  depends_on = [
    module.foundation
  ]
  enable_apis = var.enable_apis
}

module "github_parser" {
  source                         = "../fourkeys-data-source"
  for_each                       = toset(var.parsers)
  project_id                     = var.project_id
  parser_service_name            = each.value
  parser_container_url           = local.parser_container_urls[each.value]
  region                         = var.region
  fourkeys_service_account_email = module.foundation.fourkeys_service_account_email
  enable_apis                    = var.enable_apis
  depends_on = [
    module.fourkeys_images
  ]
}

module "dashboard" {
  source                         = "../fourkeys-dashboard"
  project_id                     = var.project_id
  region                         = var.region
  dashboard_container_url        = local.dashboard_container_url
  fourkeys_service_account_email = module.foundation.fourkeys_service_account_email
  enable_apis                    = var.enable_apis
  depends_on = [
    module.fourkeys_images
  ]
}
