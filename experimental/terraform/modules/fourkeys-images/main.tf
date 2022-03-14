module "gcloud_build_dashboard" {
  source                 = "terraform-google-modules/gcloud/google"
  version                = "~> 2.0"
  platform               = "linux"
  additional_components  = []
  create_cmd_entrypoint  = "gcloud"
  create_cmd_body        = "builds submit ${path.module}/files/dashboard --tag=gcr.io/${var.project_id}/fourkeys-grafana-dashboard --project=${var.project_id}"
  destroy_cmd_entrypoint = "gcloud"
  destroy_cmd_body       = "container images delete gcr.io/${var.project_id}/fourkeys-grafana-dashboard --quiet"
}

module "gcloud_build_data_source" {
  source                 = "terraform-google-modules/gcloud/google"
  for_each               = toset(var.parsers)
  version                = "~> 2.0"
  platform               = "linux"
  additional_components  = []
  create_cmd_entrypoint  = "gcloud"
  create_cmd_body        = "builds submit ${path.module}/files/bq-workers/${each.value}-parser --tag=gcr.io/${var.project_id}/${each.value}-parser --project=${var.project_id}"
  destroy_cmd_entrypoint = "gcloud"
  destroy_cmd_body       = "container images delete gcr.io/${var.project_id}/${each.value}-parser --quiet"
}

module "gcloud_build_event_handler" {
  source                 = "terraform-google-modules/gcloud/google"
  version                = "~> 2.0"
  create_cmd_entrypoint  = "gcloud"
  create_cmd_body        = "builds submit ${path.module}/files/event_handler --tag=gcr.io/${var.project_id}/event-handler --project=${var.project_id}"
  destroy_cmd_entrypoint = "gcloud"
  destroy_cmd_body       = "container images delete gcr.io/${var.project_id}/event-handler --quiet"
}
