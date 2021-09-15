# Data and Local variables
data "google_project" "project" {
  project_id = var.project_id
}

locals {
  cloud_build_service_account = "${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
  services = toset([
    "cloudapis.googleapis.com",
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "containerregistry.googleapis.com",
    "secretmanager.googleapis.com"

  ])
}

# Service Accounts and IAM

resource "google_service_account" "fourkeys" {
  project      = var.project_id
  account_id   = "fourkeys"
  display_name = "Service Account for Four Keys resources"
}

resource "google_project_iam_member" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${local.cloud_build_service_account}"
}

resource "google_project_iam_member" "bigquery_user" {
  project = var.project_id
  role    = "roles/bigquery.user"
  member  = "serviceAccount:${google_service_account.fourkeys.email}"
  depends_on = [
    google_service_account.fourkeys
  ]
}

resource "google_project_iam_member" "cloud_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.fourkeys.email}"
  depends_on = [
    google_service_account.fourkeys
  ]
}


# Services and API's

resource "google_project_service" "all" {
  project                    = var.project_id
  for_each                   = local.services
  service                    = each.value
  disable_dependent_services = true
}

resource "google_cloud_run_service" "event_handler" {
  name     = "event-handler"
  project  = var.project_id
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/event-handler"
        env {
          name  = "PROJECT_NAME"
          value = var.project_id
        }
      }
      service_account_name = google_service_account.fourkeys.email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true

  depends_on = [
    google_project_service.all["run.googleapis.com"]
  ]

}

# resource "google_cloud_run_service_iam_binding" "noauth" {
#   location = var.google_region
#   project  = var.google_project_id
#   service  = "event-handler"

#   role       = "roles/run.invoker"
#   members    = ["allUsers"]
#   depends_on = [google_cloud_run_service.event_handler]
# }

# resource "google_secret_manager_secret" "event_handler" {
#   secret_id = "event-handler"
#   replication {
#     automatic = true
#   }
#   depends_on = [google_project_service.sm_api]
# }

# resource "random_id" "event_handler_random_value" {
#   byte_length = "20"
# }

# resource "google_secret_manager_secret_version" "event_handler" {
#   secret      = google_secret_manager_secret.event_handler.id
#   secret_data = random_id.event_handler_random_value.hex
# }

# resource "google_secret_manager_secret_iam_member" "event_handler" {
#   secret_id = google_secret_manager_secret.event_handler.id
#   role      = "roles/secretmanager.secretAccessor"
#   member    = "serviceAccount:${google_service_account.fourkeys.email}"
# }
