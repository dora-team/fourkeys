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
}

module "pubsub" {
  source  = "terraform-google-modules/pubsub/google"
  version = "~> 1.8"

  topic      = "gcr" # see https://cloud.google.com/artifact-registry/docs/configure-notifications for set up and consumption
  project_id = var.google_project_id
}
