terraform {
  required_version = ">= 0.15"
  required_providers {
    google = {
      version = "~> 3.86.0"
    }
  }
}

module "fourkeys" {
  source = "../modules/fourkeys"
  project_id = var.project_id
  enable_apis = true
  region = var.region
  bigquery_region = var.bigquery_region
  parsers = var.parsers
}