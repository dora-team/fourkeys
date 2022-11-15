module "fourkeys" {
  source              = "../modules/fourkeys"
  project_id          = var.project_id
  enable_apis         = var.enable_apis
  region              = var.region
  bigquery_region     = var.bigquery_region
  parsers             = var.parsers
}
