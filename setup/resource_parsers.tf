module "data_parser_service" {
  for_each                       = toset(var.parsers)
  source                         = "./data_parser"
  parser_service_name            = each.key
  google_project_id              = var.google_project_id
  google_region                  = var.google_region
  fourkeys_service_account_email = google_service_account.fourkeys.email

  depends_on = [
    google_project_service.run_api,
    google_bigquery_dataset.four_keys
  ]
}
