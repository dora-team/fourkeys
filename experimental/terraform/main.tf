resource "random_id" "project_id" {
    prefix = "fourkeys-"
    byte_length = 4
}

data "google_billing_account" "acct" {
  display_name = var.billing_account
}

resource "google_project" "fourkeys-project" {
  name       = "Four Keys Dashboard"
  project_id = random_id.project_id.dec
  billing_account = data.google_billing_account.acct.id
  # org_id = "" # TODO: add support for orgs
  # folder_id = "" # TODO: add support for folders
}