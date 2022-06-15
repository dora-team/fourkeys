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
