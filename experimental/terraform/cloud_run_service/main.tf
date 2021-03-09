# data "google_project" "prj" {
#   project_id = var.google_project_id
# }

# locals {
#   container_image_registry_path = "gcr.io/${var.google_project_id}/${var.service_name}"
# }

resource "google_cloud_run_service_iam_binding" "noauth" {
  location = google_cloud_run_service.cloud_run_service.location
  project  = google_cloud_run_service.cloud_run_service.project
  service  = google_cloud_run_service.cloud_run_service.name

  role    = "roles/run.invoker"
  members = ["allUsers"]
}

resource "google_cloud_run_service" "cloud_run_service" {
  name     = var.service_name
  location = var.google_region

  template {
    spec {
      containers {
        image = "gcr.io/${var.google_project_id}/${var.service_name}"
        env {
          name  = "PROJECT_NAME"
          value = var.google_project_id
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true

}