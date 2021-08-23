# notification configuration file generation
data "template_file" "http_notification" {
  template = file("${path.module}/templates/http.tpl")
  vars = {
    filter = "build.status == Build.Status.SUCCESS && build.substitutions[\"BRANCH_NAME\"] == \"${var.branch}\" && build.build_trigger_id == \"${var.trigger_id}\""
    url    = var.url
  }
}
# upload notification configuration file to storage bucket
resource "google_storage_bucket_object" "http_notification" {
  name    = "configuration/http-notification-for-${var.trigger_name}.yaml"
  content = data.template_file.http_notification.rendered
  bucket  = var.storage_bucket.name
}
# deploy cloud run notification service
resource "google_cloud_run_service" "http_notification" {
  name     = "http-notifier-for-${var.trigger_name}"
  location = var.google_region

  template {
    spec {
      containers {
        image = "us-east1-docker.pkg.dev/gcb-release/cloud-build-notifiers/http:latest"
        env {
          name  = "CONFIG_PATH"
          value = "${var.storage_bucket.url}/configuration/http-notification-for-${var.trigger_name}.yaml"
        }
        env {
          name  = "PROJECT_ID"
          value = var.google_project_id
        }
      }
      service_account_name = var.service_account_email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true

  depends_on = [
    google_storage_bucket_object.http_notification,
  ]
}

