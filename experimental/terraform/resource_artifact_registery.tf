resource "google_project_service" "ar_api" {
  service = "artifactregistry.googleapis.com"
}

resource "google_artifact_registry_repository" "default" {
  provider = google-beta

  description   = "Container Repository"
  format        = "DOCKER"
  location      = var.google_region
  project       = var.google_project_id
  repository_id = "default"

  depends_on = [
    google_project_service.ar_api,
  ]
}
