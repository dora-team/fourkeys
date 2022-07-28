module "fourkeys" {
  source              = "../modules/fourkeys"
  project_id          = var.project_id
  enable_apis         = var.enable_apis
  enable_build_images = var.enable_build_images
  region              = var.region
  bigquery_region     = var.bigquery_region
  parsers             = var.parsers
  # Uncomment the following container url variables if enable_build_images is set to false:
  # event_handler_container_url = var.event_handler_container_url
  # dashboard_container_url     = var.dashboard_container_url
  # parser_container_urls       = var.parser_container_urls
}
