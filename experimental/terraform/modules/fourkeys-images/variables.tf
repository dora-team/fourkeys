variable "project_id" {
  type = string
}

variable "enable_apis" {
  type        = bool
  description = "Toggle to include required APIs."
  default     = false
}

variable "parser_service_name" {
  type        = string
  description = "Data source name. Must be 'github', 'gitlab', 'cloud-build', or 'tekton'"
}
