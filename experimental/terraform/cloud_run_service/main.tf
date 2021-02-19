resource "google_cloud_run_service" "cloud_run_service" {
  name     = "event-handler"
  location = var.google_region

  template {
    spec {
      containers {
        image = "gcr.io/stanke-fourkeys-20210217/event-handler:latest"
        env {
          name  = "PROJECT_NAME"
          value = var.google_project_id
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true

  depends_on = [
    null_resource.app_container,
  ]

}

data "google_iam_policy" "run_noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.cloud_run_service.location
  project  = google_cloud_run_service.cloud_run_service.project
  service  = google_cloud_run_service.cloud_run_service.name

  policy_data = data.google_iam_policy.run_noauth.policy_data
}

resource "null_resource" "app_container" {
  provisioner "local-exec" {
    # build event-handler container using Dockerfile
    command = "gcloud builds submit ${var.container_source_path} --tag=${var.container_image_path} --project=${var.google_project_id}"
  }

}