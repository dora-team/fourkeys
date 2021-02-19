# resource "google_cloud_run_service" "event_handler_service" {
#   name = "event-handler"
#   location = var.google_region

#   template {
#     spec {
#       containers {
#         image = "gcr.io/stanke-fourkeys-20210217/event-handler:latest"
#         env {
#           name = "PROJECT_NAME"
#           value = var.google_project_id
#         }
#       }
#     }
#   }

#   traffic {
#     percent = 100
#     latest_revision = true
#   }

#   autogenerate_revision_name = true

#   depends_on = [
#     null_resource.app_container,
#   ]

# }

resource "null_resource" "app_container" {
  provisioner "local-exec" {
    # build event-handler container using Dockerfile
    command = "gcloud builds submit ${var.container_source_path} --tag=${var.container_image_path} --project=${var.google_project_id}"
  }

}