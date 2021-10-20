terraform {
  required_version = ">= 0.15"
  required_providers {
    google = {
      version = "~> 3.86.0"
    }
  }
}

module "foundation" {
  source     = "github.com/GoogleCloudPlatform/fourkeys//experimental/terraform/modules/fourkeys-foundation"
  project_id = var.project_id
}
output "event_handler_endpoint" {
  value = module.foundation.event_handler_endpoint
}

output "event_handler_secret" {
  value = module.foundation.event_handler_secret
  sensitive = true
}

module "bigquery" {
  source                   = "github.com/GoogleCloudPlatform/fourkeys//experimental/terraform/modules/fourkeys-bigquery"
  project_id               = var.project_id
  bigquery_region          = var.region
  fourkeys_service_account_email = module.foundation.fourkeys_service_account_email
  depends_on = [
    module.foundation
  ]
}

module "github_parser" {
  source                   = "github.com/GoogleCloudPlatform/fourkeys//experimental/terraform/modules/fourkeys-data-source"
  for_each  = toset(var.parsers)
  project_id               = var.project_id
  parser_service_name          = each.value
  region  = var.region
  fourkeys_service_account_email = module.foundation.fourkeys_service_account_email
}