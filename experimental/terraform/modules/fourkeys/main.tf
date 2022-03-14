module "fourkeys_images" {
  source      = "../fourkeys-images"
  project_id  = var.project_id
  enable_apis = var.enable_apis
  parsers     = var.parsers
}

module "foundation" {
  source      = "../fourkeys-foundation"
  project_id  = var.project_id
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
  fourkeys_service_account_email = module.foundation.fourkeys_service_account_email
  enable_apis                    = var.enable_apis
  depends_on = [
    module.fourkeys_images
  ]
}
