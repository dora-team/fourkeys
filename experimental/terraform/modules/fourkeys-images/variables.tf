variable "project_id" {
  type = string
}

variable "enable_apis" {
  type        = bool
  description = "Toggle to include required APIs."
  default     = false
}
