output "event-handler_endpoint" {
  value = google_cloud_run_service.event-handler.status[0]["url"]
}

output "event-handler_secret" {
  value     = google_secret_manager_secret_version.event-handler.secret_data
  sensitive = true
}

output "dashboard_endpoint" {
  value = google_cloud_run_service.dashboard.status[0]["url"]
}

output "fourkeys_service_account_email" {
  value = google_service_account.fourkeys.email
}



