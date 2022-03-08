terraform {
  required_version = ">= 0.15"
  required_providers {
    google = {
      version = "~> 3.86.0"
    }
  }
}

module "fourkeys" {
  source = "../modules/fourkeys-complete"
  project_id = var.project_id
  region = var.region
  bigquery_region = var.bigquery_region
  parsers = var.parsers
}