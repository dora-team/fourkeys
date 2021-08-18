output "event_handler_endpoint" {
  value = google_cloud_run_service.event_handler.status[0]["url"]
}

output "event_handler_dns_data" {
  value = try(google_cloud_run_domain_mapping.event_handler[0].status[0]["resource_records"][0].rrdata, null)
}

output "event_handler_dns_name" {
  value = try(google_cloud_run_domain_mapping.event_handler[0].status[0]["resource_records"][0].name, null)
}

output "event_handler_dns_type" {
  value = try(google_cloud_run_domain_mapping.event_handler[0].status[0]["resource_records"][0].type, null)
}

output "event_handler_name_servers" {
  value = try(module.event_hander_dns[0].name_servers, null)
}

output "event_handler_secret" {
  value     = google_secret_manager_secret_version.event_handler.secret_data
  sensitive = true
}

output "looker_service_account_email" {
  value = try(module.service_account_for_looker[0].email, null)
}
