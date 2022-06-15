
# Event handler resources







resource "google_secret_manager_secret" "event_handler" {
  project   = var.project_id
  secret_id = "event-handler"
  replication {
    automatic = true
  }
  depends_on = [google_project_service.foundation_services]
}

resource "random_id" "event_handler_random_value" {
  byte_length = "20"
}

resource "google_secret_manager_secret_version" "event_handler" {
  secret      = google_secret_manager_secret.event_handler.id
  secret_data = random_id.event_handler_random_value.hex
  depends_on  = [google_secret_manager_secret.event_handler]
}

resource "google_secret_manager_secret_iam_member" "event_handler" {
  project    = var.project_id
  secret_id  = google_secret_manager_secret.event_handler.id
  role       = "roles/secretmanager.secretAccessor"
  member     = "serviceAccount:${google_service_account.fourkeys.email}"
  depends_on = [google_secret_manager_secret.event_handler, google_secret_manager_secret_version.event_handler]
}
