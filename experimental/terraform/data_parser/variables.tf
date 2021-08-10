variable "cloud_build_branch" {
  type = string
  description = "(optional) the branch to trigger event handler and bq worker builds"
  default = "main"
}

variable "google_project_id" {
  type = string
}

variable "fourkeys_service_account_email" {
  type = string
}

variable "google_region" {
  type = string
}

variable "owner" {
  type = string
  description = "The owner of code repository"
}

variable "parser_service_name" {
  type = string
}

variable "repository" {
  type = string
  description = "The name of the git repository"
}
