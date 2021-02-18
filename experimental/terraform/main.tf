terraform {
  required_version = ">= 0.14"
}

resource "google_project_service" "run_api" {
  service = "run.googleapis.com"
}

data "google_iam_policy" "run_noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

# TODO: move cloud run service resource to a module

resource "google_cloud_run_service" "event_handler_service" {
  name = "event-handler"
  location = var.google_region

  template {
    spec {
      containers {
        image = "gcr.io/stanke-fourkeys-20210217/event-handler:latest"
        env {
          name = "PROJECT_NAME"
          value = var.google_project_id
        }
      }
    }
  }

  traffic {
    percent = 100
    latest_revision = true
  }

  autogenerate_revision_name = true

  depends_on = [
    google_project_service.run_api,
  ]

}