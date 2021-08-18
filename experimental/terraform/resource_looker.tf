module "service_account_for_looker" {
  source        = "terraform-google-modules/service-accounts/google"
  version       = "~> 3.0"

  display_name  = "Looker"
  description   = "Looker accessor account (managed by Terraform)"
  project_id    = var.google_project_id
  names         = ["looker"]
  project_roles = [
    "${var.google_project_id}=>roles/bigquery.user",
  ]
}

resource "google_project_organization_policy" "service_account_keys_policy" {
  project    = var.google_project_id
  constraint = "iam.disableServiceAccountKeyCreation"

  list_policy {
    allow {
      all = false
    }
  }
}
