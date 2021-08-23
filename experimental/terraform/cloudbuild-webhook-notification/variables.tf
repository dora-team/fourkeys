variable "branch" {
  description = "The production branch to send deployment notification for."
  default     = "main"
  type        = string
}

variable "google_project_id" {
  description = "The project id that resources will be deployed too."
  type        = string
}

variable "google_region" {
  description = "(Optional) location region identifier to deploy resources too, see https://cloud.google.com/compute/docs/regions-zones"
  default     = "us-central1"
  type        = string
}

variable "service_account_email" {
  description = "The service account that is associated with the pubsub messages"
  type = string
}

variable "storage_bucket" {
 description = "Storage bucket resource to upload configurations to."
}

variable "trigger_id" {
  description = "The Cloud Build Trigger ID to associate with notification."
  type        = string
}

variable "trigger_name" {
  description = "The Cloud Build Trigger name to associate with notification."
  type        = string
}

variable "url" {
  description = "The event_handler URL to receive notifications"
}