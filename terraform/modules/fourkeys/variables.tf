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
  description = "List of data parsers to configure. Acceptable values are: 'github', 'gitlab', 'cloud-build', 'tekton'"
}

variable "enable_apis" {
  type        = bool
  description = "Toggle to include required APIs."
  default     = false
}

variable "enable_build_images" {
  type        = bool
  description = "Toggle to build fourkeys images and upload to container registry. If set to false, URLs for images must be provided via the container_url variables"
  default     = true
}

variable "event_handler_container_url" {
  type = string
  description = "If 'enable_build_images' is set to false, this is the URL for the event_handler container image."
  default = ""
}

variable "dashboard_container_url" {
  type = string
  description = "If 'enable_build_images' is set to false, this is the URL for the dashboard container image."
  default = ""
}

variable "parser_container_urls" {
  type = map(any)
  description = "If 'enable_build_images' is set to false, this is the URL for the parser container images. e.g: {'github': 'gcr.io/youproject/github-parser', 'gitlab': 'gcr.io/youproject/gitlab-parser'} "
  default = {}
}