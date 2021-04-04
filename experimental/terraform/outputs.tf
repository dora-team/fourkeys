output "event-handler-endpoint" {
  value = module.event_handler_service.cloud_run_endpoint
}

output "event-handler-secret" {
  value     = google_secret_manager_secret_version.event-handler-secret-version.secret_data
  sensitive = true
}