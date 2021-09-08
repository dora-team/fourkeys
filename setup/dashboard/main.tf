resource "google_cloud_run_service" "dashboard" {
  name     = fourkeys-grafana-dashboard
  location = var.google_region

  template {
    spec {
      containers {
        image = "gcr.io/${var.google_project_id}/fourkeys-grafana-dashboard"
        env {
          name  = "PROJECT_NAME"
          value = var.google_project_id
        }
      }
      service_account_name = var.fourkeys_service_account_email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true
}
