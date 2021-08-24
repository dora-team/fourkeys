output "cloud_run_endpoint" {
  value = google_cloud_run_service.parser.status[0]["url"]
}

output "trigger_name" {
  value = module.cloudbuild_for_parser.name
}

output "notification_url" {
  value = module.cloudbuild_notification.url
}
