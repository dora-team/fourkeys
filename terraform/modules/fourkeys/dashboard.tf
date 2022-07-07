resource "google_cloud_run_service" "dashboard" {
  name     = "fourkeys-grafana-dashboard"
  location = var.region
  project  = var.project_id
  template {
    spec {
      containers {
        ports {
          name           = "http1"
          container_port = 3000
        }
        image = local.dashboard_container_url
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
  metadata {
    labels = { "created_by" : "fourkeys" }
  }
  autogenerate_revision_name = true
  depends_on = [
    module.fourkeys_images
  ]
}

resource "google_cloud_run_service_iam_binding" "dashboard_noauth" {
  location = var.region
  project  = var.project_id
  service  = "fourkeys-grafana-dashboard"

  role       = "roles/run.invoker"
  members    = ["allUsers"]
  depends_on = [google_cloud_run_service.dashboard]
}
