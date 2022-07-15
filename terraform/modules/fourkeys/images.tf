module "fourkeys_images" {
  source      = "../fourkeys-images"
  count       = var.enable_build_images ? 1 : 0
  project_id  = var.project_id
  enable_apis = var.enable_apis
  parsers     = var.parsers
}