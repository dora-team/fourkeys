module "github_parser" {
  source                         = "../fourkeys-github-parser"
  count                          = contains(var.parsers, "github") ? 1 : 0
  project_id                     = var.project_id
  parser_container_url           = local.parser_container_urls["github"]
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
  parser_container_url           = local.parser_container_urls["gitlab"]
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
  parser_container_url           = local.parser_container_urls["tekton"]
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
  parser_container_url           = local.parser_container_urls["cloud-build"]
  region                         = var.region
  fourkeys_service_account_email = google_service_account.fourkeys.email
  enable_apis                    = var.enable_apis
  depends_on = [
    module.fourkeys_images
  ]
}