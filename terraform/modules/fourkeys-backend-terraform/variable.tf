variable "project_id" {
  type        = string
  description = "project to deploy four keys resources to"
}

variable "uniform_bucket_level_access" {
  type        = bool
  default     = true
  description = "Enables Uniform bucket-level access access to a bucket"
}

variable "location_storage" {
  type        = string
  default     = "US"
  description = "Region to deploy storage resources in."
  validation {
    condition     = can(regex("^(US|EU)$", var.location_storage))
    error_message = "The value for 'location_storage' must be one of: 'US','EU'."
  }
}
