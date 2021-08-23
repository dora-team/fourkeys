module "data_parser_service" {
  for_each                        = toset(var.parsers)
  source                          = "./data_parser"

  cloud_build_branch              = var.cloud_build_branch
  cloud_run_service_account_email = module.service_account_for_cloudrun.email
  fourkeys_service_account_email  = google_service_account.fourkeys.email
  google_project_id               = var.google_project_id
  google_region                   = var.google_region
  owner                           = var.owner
  notification_url                = length(var.mapped_domain) > 0 ? try("https://${var.subdomain}.${var.mapped_domain}", null) : google_cloud_run_service.event_handler.status[0]["url"]
  parser_service_name             = each.key
  repository                      = var.repository
  storage_bucket                  = module.bucket_for_cloudrun.bucket

  depends_on = [
    google_project_service.run_api
  ]
}
