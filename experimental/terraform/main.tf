terraform {
  required_version = ">= 0.14"
}

resource "google_project_service" "run_api" {
  service = "run.googleapis.com"
  project = var.google_project_id
}

resource "google_project_service" "cloudbuild_api" {
  service = "cloudbuild.googleapis.com"
  project = var.google_project_id
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
    null_resource.event_handler_container,
  ]

}

resource "null_resource" "event_handler_container" {
  provisioner "local-exec" {
    # build event-handler container using Dockerfile
    command = "gcloud builds submit ../../event_handler --tag=gcr.io/${var.google_project_id}/event-handler --project=${var.google_project_id}"
  }

  depends_on = [
    google_project_service.cloudbuild_api,
  ]

}