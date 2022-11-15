
resource "google_project_service" "fourkeys_services" {
  project            = var.project_id
  for_each           = toset(local.services)
  service            = each.value
  disable_on_destroy = false
}

resource "time_sleep" "wait_for_services" {
  depends_on = [google_project_service.fourkeys_services]

  create_duration = "30s"
}