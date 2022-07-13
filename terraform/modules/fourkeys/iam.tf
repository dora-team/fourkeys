resource "google_project_iam_member" "parser_bq_project_access" {
  project = var.project_id
  role    = "roles/bigquery.user"
  member  = "serviceAccount:${google_service_account.fourkeys.email}"
}

resource "google_project_iam_member" "parser_run_invoker" {
  project = var.project_id
  member  = "serviceAccount:${google_service_account.fourkeys.email}"
  role    = "roles/run.invoker"
}

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
