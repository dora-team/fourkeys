module "circleci_parser" {
  source                         = "../fourkeys-circleci-parser"
  count                          = contains(var.parsers, "circleci") ? 1 : 0
  project_id                     = var.project_id
  parser_container_url           = local.circleci_parser_url
  region                         = var.region
  fourkeys_service_account_email = google_service_account.fourkeys.email
  enable_apis                    = var.enable_apis
  depends_on = [
    module.fourkeys_images
  ]
}

module "github_parser" {
  source                         = "../fourkeys-github-parser"
  count                          = contains(var.parsers, "github") ? 1 : 0
  project_id                     = var.project_id
  parser_container_url           = local.github_parser_url
  region                         = var.region
  fourkeys_service_account_email = google_service_account.fourkeys.email
  enable_apis                    = var.enable_apis
  depends_on = [
    module.fourkeys_images
  ]
}

module "gitlab_parser" {
  source                         = "../fourkeys-gitlab-parser"
  count                          = contains(var.parsers, "gitlab") ? 1 : 0
  project_id                     = var.project_id
  parser_container_url           = local.gitlab_parser_url
  region                         = var.region
  fourkeys_service_account_email = google_service_account.fourkeys.email
  enable_apis                    = var.enable_apis
  depends_on = [
    module.fourkeys_images
  ]
}

module "pagerduty_parser" {
  source                         = "../fourkeys-pagerduty-parser"
  count                          = contains(var.parsers, "pagerduty") ? 1 : 0
  project_id                     = var.project_id
  parser_container_url           = local.pagerduty_parser_url
  region                         = var.region
  fourkeys_service_account_email = google_service_account.fourkeys.email
  enable_apis                    = var.enable_apis
  depends_on = [
    module.fourkeys_images
  ]
}

module "tekton_parser" {
  source                         = "../fourkeys-tekton-parser"
  count                          = contains(var.parsers, "tekton") ? 1 : 0
  project_id                     = var.project_id
  parser_container_url           = local.tekton_parser_url
  region                         = var.region
  fourkeys_service_account_email = google_service_account.fourkeys.email
  enable_apis                    = var.enable_apis
  depends_on = [
    module.fourkeys_images
  ]
}

module "cloud_build_parser" {
  source                         = "../fourkeys-cloud-build-parser"
  count                          = contains(var.parsers, "cloud-build") ? 1 : 0
  project_id                     = var.project_id
  parser_container_url           = local.cloud_build_parser_url
  region                         = var.region
  fourkeys_service_account_email = google_service_account.fourkeys.email
  enable_apis                    = var.enable_apis
  depends_on = [
    module.fourkeys_images
  ]
}