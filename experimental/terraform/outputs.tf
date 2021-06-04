output "event-handler-endpoint" {
  value = google_cloud_run_service.event_handler.status[0]["url"]
}

output "event-handler-secret" {
  value     = google_secret_manager_secret_version.event-handler-secret-version.secret_data
  sensitive = true
}