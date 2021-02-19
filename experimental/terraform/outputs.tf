output "cloud_run_endpoints" {
  value = [for x in module.cloud_run_service[*]["cloud_run_endpoint"] : x]
}