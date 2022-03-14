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

output "dashboard_url" {
    value = "gcr.io/${var.project_id}/fourkeys-grafana-dashboard"
}