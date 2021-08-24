data "google_project" "current" {}

# cloud run service account
# grant clound run invoker permissions
module "service_account_for_cloudrun" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "~> 3.0"
  project_id = var.google_project_id
  names      = ["cloudrun-notifier"]
  project_roles = [
    "${var.google_project_id}=>roles/viewer",
    "${var.google_project_id}=>roles/run.invoker",
    "${var.google_project_id}=>roles/storage.objectViewer"
  ]
}
# grant project Pub/Sub permissions to create authentication tokens
module "service_account-iam-bindings" {
  source = "terraform-google-modules/iam/google//modules/service_accounts_iam"

  service_accounts = module.service_account_for_cloudrun.emails_list
  project          = var.google_project_id
  mode             = "additive"
  bindings = {
    "roles/iam.serviceAccountTokenCreator" = [
      "serviceAccount:service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com",
    ]
  }
}
# create the cloud-builds topic
# create a Pub/Sub push subscriber for cloudbuild http notifier
module "pubsub" {
  source  = "terraform-google-modules/pubsub/google"
  version = "~> 1.8"

  topic      = "cloud-builds" # see https://cloud.google.com/build/docs/configuring-notifications/configure-https for set up and consumption
  project_id = var.google_project_id

  push_subscriptions = concat([for item in var.parsers : {
      name            = module.data_parser_service[item].trigger_name
      push_endpoint   = module.data_parser_service[item].notification_url
      service_account = module.service_account_for_cloudrun.email
    }],[{
      name            = module.event_handler_cloudbuild_trigger.name
      push_endpoint   = module.event_handler_cloudbuild_notification.url
      service_account = module.service_account_for_cloudrun.email
    }])
}
