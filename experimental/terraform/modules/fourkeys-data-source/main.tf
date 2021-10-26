data "google_project" "project" {
  project_id = var.project_id
}
data "google_service_account" "pubsub_service_account" {
  account_id = "service-${data.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}
module "gcloud_build_data_source" {
  source                 = "terraform-google-modules/gcloud/google"
  version                = "~> 2.0"
  platform               = "linux"
  additional_components  = []
  create_cmd_entrypoint  = "gcloud"
  create_cmd_body        = "builds submit ${path.module}/files/bq-workers/${var.parser_service_name}-parser --tag=gcr.io/${var.project_id}/${var.parser_service_name}-parser --project=${var.project_id}"
  destroy_cmd_entrypoint = "gcloud"
  destroy_cmd_body       = "container images delete gcr.io/${var.project_id}/${var.parser_service_name}-parser --quiet"
}

resource "google_cloud_run_service" "parser" {
  project  = var.project_id
  name     = var.parser_service_name
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/${var.parser_service_name}-parser"
        env {
          name  = "PROJECT_NAME"
          value = var.project_id
        }
      }
      service_account_name = var.fourkeys_service_account_email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true
  depends_on = [
    module.gcloud_build_data_source
  ]
}

resource "google_pubsub_topic" "parser" {
  project = var.project_id
  name    = var.parser_service_name
}

resource "google_pubsub_topic_iam_member" "event_handler" {
  project = var.project_id
  topic   = google_pubsub_topic.parser.id
  role    = "roles/editor"
  member  = "serviceAccount:${var.fourkeys_service_account_email}"
}

resource "google_pubsub_subscription" "parser" {
  project = var.project_id
  name    = "${var.parser_service_name}-subscription"
  topic   = google_pubsub_topic.parser.id

  push_config {
    push_endpoint = google_cloud_run_service.parser.status[0]["url"]

    oidc_token {
      service_account_email = var.fourkeys_service_account_email
    }
  }
}


resource "google_project_iam_member" "pubsub_service_account_token_creator" {
  project = var.project_id
  member  = "serviceAccount:${data.pubsub_service_account.email}"
  role    = "roles/iam.serviceAccountTokenCreator"
}
