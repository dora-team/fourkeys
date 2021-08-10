module "data_parser_service" {
  for_each                       = toset(var.parsers)
  source                         = "./data_parser"

  branch                         = var.cloud_build_branch
  fourkeys_service_account_email = google_service_account.fourkeys.email
  google_project_id              = var.google_project_id
  google_region                  = var.google_region
  owner                          = var.owner
  parser_service_name            = each.key
  repository                     = var.repository

  depends_on = [
    google_project_service.run_api
  ]
}
