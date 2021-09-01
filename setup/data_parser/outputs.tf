output "cloud_run_endpoint" {
  value = google_cloud_run_service.parser.status[0]["url"]
}