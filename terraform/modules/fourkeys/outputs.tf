output "event_handler_endpoint" {
  value = module.foundation.event_handler_endpoint
}

output "event_handler_secret" {
  value     = module.foundation.event_handler_secret
  sensitive = true
}

output "dashboard_endpoint" {
  value = google_cloud_run_service.dashboard.status[0]["url"]
}