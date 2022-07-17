resource "google_cloud_run_service" "event-handler" {
  name     = "event-handler"
  project  = var.project_id
  location = var.region

  template {
    spec {
      containers {
        image = local.event-handler_container_url
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

resource "google_cloud_run_service_iam_binding" "event-handler_noauth" {
  location   = var.region
  project    = var.project_id
  service    = google_cloud_run_service.event-handler.name
  role       = "roles/run.invoker"
  members    = ["allUsers"]
  depends_on = [google_cloud_run_service.event-handler]
}

resource "google_secret_manager_secret" "event-handler" {
  project   = var.project_id
  secret_id = "event-handler"
  replication {
    automatic = true
  }
}

resource "random_id" "event-handler_random_value" {
  byte_length = "20"
}

resource "google_secret_manager_secret_version" "event-handler" {
  secret      = google_secret_manager_secret.event-handler.id
  secret_data = random_id.event-handler_random_value.hex
  depends_on  = [google_secret_manager_secret.event-handler]
}

resource "google_secret_manager_secret_iam_member" "event-handler" {
  project    = var.project_id
  secret_id  = google_secret_manager_secret.event-handler.id
  role       = "roles/secretmanager.secretAccessor"
  member     = "serviceAccount:${google_service_account.fourkeys.email}"
  depends_on = [google_secret_manager_secret.event-handler, google_secret_manager_secret_version.event-handler]
}
