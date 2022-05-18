output "dashboard_endpoint" {
  value = google_cloud_run_service.dashboard.status[0]["url"]
}