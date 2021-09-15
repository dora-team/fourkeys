module "foundation" {
  source     = "../modules/fourkeys-foundation"
  project_id = "fourkeytest"
}

module "bigquery" {
  source                   = "../modules/fourkeys-bigquery"
  project_id               = "fourkeytest"
  bigquery_region          = "us-central1"
  fourkeys_service_account = module.foundation.fourkeys_service_account_email
  depends_on = [
    module.foundation
  ]
}
