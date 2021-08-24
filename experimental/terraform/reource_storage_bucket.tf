# create storage bucket for notification configuration file
module "bucket_for_cloudrun" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "~> 1.3"

  name          = "${var.google_project_id}-${var.google_region}-cloudrun"
  project_id    = var.google_project_id
  location      = var.google_region
  force_destroy = true
}
