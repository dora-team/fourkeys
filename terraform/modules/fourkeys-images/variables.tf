variable "project_id" {
  type = string
}

variable "enable_apis" {
  type        = bool
  description = "Toggle to include required APIs."
  default     = false
}

variable "parsers" {
  type        = list(string)
  description = "List of data parsers to configure. Acceptable values are: 'github', 'gitlab', 'cloud-build', 'tekton'"
}

variable "registry_hostname" {
  type        = string
  description = "Define registry hostname"
  default     = "gcr.io"
}

variable "gcloud_builds_extra_arguments" {
  type        = string
  description = "Set extra arguments for gcloud builds command"
  default     = ""
}
