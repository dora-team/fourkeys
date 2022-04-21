resource "google_project_service" "sm_api" {
  service = "secretmanager.googleapis.com"
}

resource "google_cloud_run_service" "event_handler" {
  name     = "event-handler"
  location = var.google_region

  template {
    spec {
      containers {
        image = "gcr.io/${var.google_project_id}/event-handler"
        env {
          name  = "PROJECT_NAME"
          value = var.google_project_id
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

  depends_on = [
    google_project_service.run_api,
    google_bigquery_dataset.four_keys
  ]

  metadata {
    labels = { "created_by" : "fourkeys" }
  }
}

resource "google_cloud_run_service_iam_binding" "noauth" {
  location = var.google_region
  project  = var.google_project_id
  service  = "event-handler"

  role       = "roles/run.invoker"
  members    = ["allUsers"]
  depends_on = [google_cloud_run_service.event_handler]
}

resource "google_secret_manager_secret" "event_handler" {
  secret_id = "event-handler"
  replication {
    automatic = true
  }
  depends_on = [google_project_service.sm_api]
  labels     = { "created_by" : "fourkeys" }
}

resource "random_id" "event_handler_random_value" {
  byte_length = "20"
}

resource "google_secret_manager_secret_version" "event_handler" {
  secret      = google_secret_manager_secret.event_handler.id
  secret_data = random_id.event_handler_random_value.hex
}

resource "google_secret_manager_secret_iam_member" "event_handler" {
  secret_id = google_secret_manager_secret.event_handler.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.fourkeys.email}"
}