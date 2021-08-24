output "name" {
  value = google_cloud_run_service.http_notification.name
}

output "url" {
  value = google_cloud_run_service.http_notification.status[0]["url"]
}
