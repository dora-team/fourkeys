resource "google_cloud_run_service" "dashboard" {
  name     = "fourkeys-grafana-dashboard"
  location = var.region
  project = var.project_id
  template {
    spec {
      containers {
        ports {
          name  = "http1"
          container_port = 3000
        }
        image = var.dashboard_container_url
        env {
          name  = "PROJECT_NAME"
          value = var.project_id
        }
      }
      service_account_name = var.fourkeys_service_account_email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
  metadata {
    labels = {"created_by":"fourkeys"}
  }
  autogenerate_revision_name = true
}

resource "google_cloud_run_service_iam_binding" "noauth" {
  location = var.region
  project  = var.project_id
  service  = "fourkeys-grafana-dashboard"

  role       = "roles/run.invoker"
  members    = ["allUsers"]
  depends_on = [google_cloud_run_service.dashboard]
}
