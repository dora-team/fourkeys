module "fourkeys_images" {
  source      = "../fourkeys-images"
  count       = var.enable_build_images ? 1 : 0
  project_id  = var.project_id
  enable_apis = var.enable_apis
  parsers     = var.parsers
}

module "foundation" {
  source                      = "../fourkeys-foundation"
  project_id                  = var.project_id
  event_handler_container_url = local.event_handler_container_url
  enable_apis                 = var.enable_apis
  depends_on = [
    module.fourkeys_images
  ]
}