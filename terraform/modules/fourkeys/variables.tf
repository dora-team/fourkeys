variable "project_id" {
  type        = string
  description = "project to deploy four keys resources to"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "Region to deploy fource keys resources in."
}

variable "bigquery_region" {
  type        = string
  default     = "US"
  description = "Region to deploy BigQuery resources in."
  validation {
    condition     = can(regex("^(US|EU)$", var.bigquery_region))
    error_message = "The value for 'bigquery_region' must be one of: 'US','EU'."
  }
}

variable "parsers" {
  type        = list(string)
  description = "List of data parsers to configure. Acceptable values are: 'github', 'gitlab', 'cloud-build', 'tekton', 'circleci', 'pagerduty'"
}

variable "enable_apis" {
  type        = bool
  description = "Toggle to include required APIs."
  default     = false
}

variable "enable_dashboard" {
  type        = bool
  description = "Toggle to enable cloud run service creation."
  default     = true
}

variable "event_handler_container_url" {
  type        = string
  description = "The URL for the event_handler container image. A default value pointing to the project's container registry is defined in under local values of this module."
  default     = ""
}

variable "dashboard_container_url" {
  type        = string
  description = "The URL for the dashboard container image. A default value pointing to the project's container registry is defined in under local values of this module."
  default     = ""
}

variable "github_parser_url" {
  type        = string
  description = "The URL for the Github parser container image. A default value pointing to the project's container registry is defined in under local values of this module."
  default     = ""
}

variable "gitlab_parser_url" {
  type        = string
  description = "The URL for the Gitlab parser container image. A default value pointing to the project's container registry is defined in under local values of this module."
  default     = ""
}

variable "cloud_build_parser_url" {
  type        = string
  description = "The URL for the Cloud Build parser container image. A default value pointing to the project's container registry is defined in under local values of this module."
  default     = ""
}

variable "tekton_parser_url" {
  type        = string
  description = "The URL for the Tekton parser container image. A default value pointing to the project's container registry is defined in under local values of this module."
  default     = ""
}

variable "circleci_parser_url" {
  type        = string
  description = "The URL for the CircleCI parser container image. A default value pointing to the project's container registry is defined in under local values of this module."
  default     = ""
}

variable "pagerduty_parser_url" {
  type        = string
  description = "The URL for the Pager Duty parser container image. A default value pointing to the project's container registry is defined in under local values of this module."
  default     = ""
}
