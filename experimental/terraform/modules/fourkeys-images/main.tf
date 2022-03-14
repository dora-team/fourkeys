module "gcloud_build_dashboard" {
  source                 = "terraform-google-modules/gcloud/google"
#   count = 0
  version                = "~> 2.0"
  platform               = "linux"
  additional_components  = []
  create_cmd_entrypoint  = "gcloud"
  create_cmd_body        = "builds submit ${path.module}/files/dashboard --tag=gcr.io/${var.project_id}/fourkeys-grafana-dashboard --project=${var.project_id}"
  destroy_cmd_entrypoint = "gcloud"
  destroy_cmd_body       = "container images delete gcr.io/${var.project_id}/fourkeys-grafana-dashboard --quiet"
}

output "dashboard_gcr_url" {
    value = "gcr.io/${var.project_id}/fourkeys-grafana-dashboard"
}

module "gcloud_build_data_source" {
  source                 = "terraform-google-modules/gcloud/google"
  version                = "~> 2.0"
  platform               = "linux"
  additional_components  = []
  create_cmd_entrypoint  = "gcloud"
  create_cmd_body        = "builds submit ${path.module}/files/bq-workers/${var.parser_service_name}-parser --tag=gcr.io/${var.project_id}/${var.parser_service_name}-parser --project=${var.project_id}"
  destroy_cmd_entrypoint = "gcloud"
  destroy_cmd_body       = "container images delete gcr.io/${var.project_id}/${var.parser_service_name}-parser --quiet"
}

output "parser_gcr_url" {
    value = "gcr.io/${var.project_id}/${var.parser_service_name}-parser"
}