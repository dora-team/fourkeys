module "gcloud_build_dashboard" {
  source                 = "terraform-google-modules/gcloud/google"
  version                = "~> 2.0"
  platform               = "linux"
  additional_components  = []
  create_cmd_entrypoint  = "gcloud"
  create_cmd_body        = "builds submit ${path.module}/files/dashboard --tag=gcr.io/${var.project_id}/fourkeys-grafana-dashboard --project=${var.project_id}"
  destroy_cmd_entrypoint = "gcloud"
  destroy_cmd_body       = "container images delete gcr.io/${var.project_id}/fourkeys-grafana-dashboard --quiet"
}

resource "time_sleep" "delay_30sec" {
  depends_on = [module.gcloud_build_dashboard]
  create_duration = "30s"
}

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
        image = "gcr.io/${var.project_id}/fourkeys-grafana-dashboard"
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
  depends_on = [
    time_sleep.delay_30sec
  ]
}

resource "google_cloud_run_service_iam_binding" "noauth" {
  location = var.region
  project  = var.project_id
  service  = "fourkeys-grafana-dashboard"

  role       = "roles/run.invoker"
  members    = ["allUsers"]
  depends_on = [google_cloud_run_service.dashboard]
}
