output "event_handler_endpoint" {
  value = google_cloud_run_service.event_handler.status[0]["url"]
}

output "event_handler_dns" {
  value = try(google_cloud_run_domain_mapping.event_handler[0].status[0]["resource_records"][0], null)
}

output "event_handler_secret" {
  value     = google_secret_manager_secret_version.event_handler.secret_data
  sensitive = true
}
