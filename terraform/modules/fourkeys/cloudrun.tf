resource "google_cloud_run_service" "event_handler" {
  name     = "event-handler"
  project  = var.project_id
  location = var.region

  template {
    spec {
      containers {
        image = var.event_handler_container_url
        env {
          name  = "PROJECT_NAME"
          value = var.project_id
        }
      }
      service_account_name = google_service_account.fourkeys.email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true
}

resource "google_cloud_run_service_iam_binding" "noauth" {
  location   = var.region
  project    = var.project_id
  service    = google_cloud_run_service.event_handler.name
  role       = "roles/run.invoker"
  members    = ["allUsers"]
  depends_on = [google_cloud_run_service.event_handler]
}