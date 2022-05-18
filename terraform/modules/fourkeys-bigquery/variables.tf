variable "project_id" {
  type = string
  description = "Project ID of the target project."
}

variable "bigquery_region" {
  type = string
  description = "Region to deploy Big Query resources."
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
