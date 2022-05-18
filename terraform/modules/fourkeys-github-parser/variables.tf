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

variable "enable_apis" {
  type        = bool
  description = "Toggle to include required APIs."
  default     = false
}

variable "parser_container_url" {
  type = string
  description = "URL of image to use in Cloud Run service configuration."
}