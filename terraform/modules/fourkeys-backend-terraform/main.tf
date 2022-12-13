locals {
  project_id                  = var.project_id
  location_storage            = var.location_storage
  uniform_bucket_level_access = var.uniform_bucket_level_access
}


resource "google_project_service" "fourkeys-backend-terraform" {
  project = local.project_id
  service = "storage.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = true
}


resource "google_storage_bucket" "fourkeys-backend-terraform" {
  name                        = "${local.project_id}-bucket-tfstate"
  force_destroy               = false
  location                    = local.location_storage
  project                     = local.project_id
  storage_class               = "STANDARD"
  uniform_bucket_level_access = local.uniform_bucket_level_access
  versioning {
    enabled = true
  }
  depends_on = [
    google_project_service.fourkeys-backend-terraform
  ]
}
