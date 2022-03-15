locals {
  event_handler_container_url = var.enable_build_images ? "gcr.io/${var.project_id}/event-handler" : ""
  dashboard_container_url     = var.enable_build_images ? "gcr.io/${var.project_id}/fourkeys-grafana-dashboard" : ""
  parser_container_urls = var.enable_build_images ? {
    "github" = "gcr.io/${var.project_id}/github-parser",
    "gitlab" = "gcr.io/${var.project_id}/gitlab-parser",
    "cloud-build" = "gcr.io/${var.project_id}/cloud-build-parser",
    "tekton" = "gcr.io/${var.project_id}/tekton-parser",
  } : {}
}

module "fourkeys_images" {
  source      = "../fourkeys-images"
  count       = var.enable_build_images ? 1 : 0
  project_id  = var.project_id
  enable_apis = var.enable_apis
  parsers     = var.parsers
}

module "foundation" {
  source      = "../fourkeys-foundation"
  project_id  = var.project_id
  event_handler_container_url = local.event_handler_container_url
  enable_apis = var.enable_apis
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
