variable "project_id" {
    type    = string
    description = "project to deploy four keys resources to"
}

variable "enable_apis" {
  type        = bool
  description = "Toggle to include required APIs."
  default     = true
}

variable "region" {
    type = string
    default = "us-central1"
    description = "Region to deploy four keys resources in."
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
  description = "List of data parsers to configure. Acceptable values are: 'github', 'gitlab', 'cloud-build', 'tekton', 'pagerduty'"
}

variable "event_handler_container_url" {
  type        = string
  description = "URL for the event_handler container image."
  default     = ""
}

variable "dashboard_container_url" {
  type        = string
  description = "URL for the dashboard container image."
  default     = ""
}

variable "parser_container_urls" {
  type        = map(any)
  description = "URL for the parser container images. e.g: {'github': 'gcr.io/youproject/github-parser', 'gitlab': 'gcr.io/youproject/gitlab-parser'} "
  default     = {}
}
