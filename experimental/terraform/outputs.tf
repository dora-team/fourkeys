output "event_handler_endpoint" {
  value = google_cloud_run_service.event_handler.status[0]["url"]
}

output "event_handler_name_servers" {
  value = try(module.event_hander_dns[0].name_servers, null)
}

output "event_handler_secret" {
  value     = google_secret_manager_secret_version.event_handler.secret_data
  sensitive = true
}
