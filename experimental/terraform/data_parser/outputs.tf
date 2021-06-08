output "cloud_run_endpoint" {
  value = google_cloud_run_service.parser_service.status[0]["url"]
}