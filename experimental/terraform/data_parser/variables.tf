variable "cloud_build_branch" {
  type = string
  description = "(optional) the branch to trigger event handler and bq worker builds"
  default = "main"
}

variable "cloud_run_service_account_email" {
  description = "The service account that is associated with the pubsub messages"
  type = string
}

variable "fourkeys_service_account_email" {
  type = string
}

variable "google_project_id" {
  type = string
}

variable "google_region" {
  type = string
}

variable "owner" {
  type = string
  description = "The owner of code repository"
}

variable "notification_url" {
  description = "The URL to send cloud build notifications too"
  type        = string
}

variable "parser_service_name" {
  type = string
}

variable "repository" {
  type = string
  description = "The name of the git repository"
}

variable "storage_bucket" {
 description = "Storage bucket resource to upload configurations to."
}
