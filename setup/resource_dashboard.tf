module "dashboard_service" {
  source                         = "./dashboard"
  google_project_id              = var.google_project_id
  google_region                  = var.google_region
  bigquery_region                = var.bigquery_region
  fourkeys_service_account_email = google_service_account.fourkeys.email

  depends_on = [
    google_project_service.run_api,
    google_bigquery_dataset.four_keys
  ]
}