variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "fourkeys_service_account_email" {
  type = string
}

variable "enable_apis" {
  type        = bool
  description = "Toggle to include required APIs."
  default     = false
}

variable "dashboard_container_url" {
  type = string
  description = "URL of dashboard container for Cloud Run configuration"
}