output "cloud_run_endpoint" {
  value = google_cloud_run_service.cloud_run_service.status[0]["url"]
}