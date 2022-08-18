locals {
    services = var.enable_apis ? [
    "cloudbuild.googleapis.com"
  ] : []
}

resource "google_project_service" "images_services" {
  project                    = var.project_id
  for_each                   = toset(local.services)
  service                    = each.value
  disable_on_destroy         = false
}

module "gcloud_build_dashboard" {
  source                 = "terraform-google-modules/gcloud/google"
  version                = "~> 2.0"
  platform               = "linux"
  additional_components  = []
  create_cmd_entrypoint  = "gcloud"
  create_cmd_body        = "builds submit ${path.module}/files/dashboard --tag=${var.registry_hostname}/${var.project_id}/fourkeys-grafana-dashboard --project=${var.project_id} ${var.gcloud_builds_extra_arguments}"
  destroy_cmd_entrypoint = "gcloud"
  destroy_cmd_body       = "container images delete ${var.registry_hostname}/${var.project_id}/fourkeys-grafana-dashboard --quiet"
}

module "gcloud_build_data_source" {
  source                 = "terraform-google-modules/gcloud/google"
  for_each               = toset(var.parsers)
  version                = "~> 2.0"
  platform               = "linux"
  additional_components  = []
  create_cmd_entrypoint  = "gcloud"
  create_cmd_body        = "builds submit ${path.module}/files/bq-workers/${each.value}-parser --tag=${var.registry_hostname}/${var.project_id}/${each.value}-parser --project=${var.project_id} ${var.gcloud_builds_extra_arguments}"
  destroy_cmd_entrypoint = "gcloud"
  destroy_cmd_body       = "container images delete ${var.registry_hostname}/${var.project_id}/${each.value}-parser --quiet"
}

module "gcloud_build_event_handler" {
  source                 = "terraform-google-modules/gcloud/google"
  version                = "~> 2.0"
  create_cmd_entrypoint  = "gcloud"
  create_cmd_body        = "builds submit ${path.module}/files/event-handler --tag=${var.registry_hostname}/${var.project_id}/event-handler --project=${var.project_id} ${var.gcloud_builds_extra_arguments}"
  destroy_cmd_entrypoint = "gcloud"
  destroy_cmd_body       = "container images delete ${var.registry_hostname}/${var.project_id}/event-handler --quiet"
}
