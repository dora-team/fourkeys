resource "google_cloud_run_service" "parser" {
  name     = "${var.parser_service_name}-worker"
  location = var.google_region

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/placeholder"
        env {
          name  = "PROJECT_NAME"
          value = var.google_project_id
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

  lifecycle {
    ignore_changes = [
      template[0].spec[0].containers[0].image
    ]
  }

}

resource "google_pubsub_topic" "parser" {
  name = var.parser_service_name
}

resource "google_pubsub_topic_iam_member" "event_handler" {
  topic  = google_pubsub_topic.parser.id
  role   = "roles/editor"
  member = "serviceAccount:${var.fourkeys_service_account_email}"
}

resource "google_pubsub_subscription" "parser" {
  name  = "${var.parser_service_name}-subscription"
  topic = google_pubsub_topic.parser.id

  push_config {
    push_endpoint = google_cloud_run_service.parser.status[0]["url"]

    oidc_token {
      service_account_email = var.fourkeys_service_account_email
    }

  }

}

module "cloudbuild_for_parser" {
  source        = "../cloudbuild-trigger"

  name          = "${var.parser_service_name}-build-deploy"
  description   = "cloud build for creating publishing ${var.parser_service_name} container images"
  project_id    = var.google_project_id
  filename      = "bq-workers/${var.parser_service_name}-parser/cloudbuild.yaml"
  owner         = var.owner
  repository    = var.repository
  branch        = var.cloud_build_branch
  include       = ["bq-workers/${var.parser_service_name}-parser/**"]
  substitutions = {
    _FOURKEYS_GCR_DOMAIN : "${var.google_region}-docker.pkg.dev"
    _FOURKEYS_REGION : var.google_region
  }
}

module "cloudbuild_notification" {
  source = "../cloudbuild-webhook-notification"

  branch                = var.cloud_build_branch
  google_project_id     = var.google_project_id
  google_region         = var.google_region
  service_account_email = var.cloud_run_service_account_email
  trigger_id            = module.cloudbuild_for_parser.id
  trigger_name          = module.cloudbuild_for_parser.name
  storage_bucket        = var.storage_bucket
  url                   = var.notification_url
}