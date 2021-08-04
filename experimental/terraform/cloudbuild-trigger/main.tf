resource "google_cloudbuild_trigger" "continuous-provisioning-trigger" {
  provider    = google-beta
  name        = replace(replace(lower(var.name), " ", "-"), "/[^a-z0-9\\-]/", "")
  description = var.description
  project     = var.project_id
  filename    = var.cloudbuild

  github {
    owner = var.owner
    name  = var.repository
    push {
      branch       = var.branch
      invert_regex = var.invert_regex
    }
  }

  included_files = var.include

  substitutions = var.substitutions
}