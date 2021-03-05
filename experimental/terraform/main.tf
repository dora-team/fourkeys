terraform {
  required_version = ">= 0.14"
}

resource "google_project_service" "run_api" {
  service = "run.googleapis.com"
  project = var.google_project_id
}

resource "google_project_service" "cloudbuild_api" {
  service = "cloudbuild.googleapis.com"
}

module "cloud_run_service" {
  source            = "./cloud_run_service"
  google_project_id = var.google_project_id
  # google_project_number = var.google_project_number
  google_region         = var.google_region
  service_name          = "event-handler"
  container_source_path = "../../event_handler"
  container_image_path  = "gcr.io/${var.google_project_id}/event-handler"

  depends_on = [
    google_project_service.run_api,
    google_project_service.cloudbuild_api,
  ]

}