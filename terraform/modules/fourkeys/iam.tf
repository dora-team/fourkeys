resource "google_project_iam_member" "parser_bq_project_access" {
  project = var.project_id
  role    = "roles/bigquery.user"
  member  = "serviceAccount:${module.foundation.fourkeys_service_account_email}"
}

resource "google_project_iam_member" "parser_run_invoker" {
  project = var.project_id
  member  = "serviceAccount:${module.foundation.fourkeys_service_account_email}"
  role    = "roles/run.invoker"
}