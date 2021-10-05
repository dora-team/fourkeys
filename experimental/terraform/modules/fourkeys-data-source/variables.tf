variable "parser_service_name" {
  type = string
  description = "Data source name. Must be 'github', 'gitlab', 'cloud-build', or 'tekton'"
}

variable "project_id" {
  type = string
  description = "Project ID of the target project."
}

variable "region" {
  type    = string
  description = "Region to deploy resources."
  default = "us-central1"
}

variable "fourkeys_service_account_email" {
  type = string
  description = "Service account for fourkeys."
}
