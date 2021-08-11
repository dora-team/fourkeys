variable "bigquery_region" {
  type = string
  validation {
    condition = (
      contains(["US", "EU"], var.bigquery_region)
    )
    error_message = "The value for 'bigquery_region' must be one of: 'US','EU'."
  }
}

variable "cloud_build_branch" {
  type = string
  description = "(optional) the branch to trigger event handler and bq worker builds"
  default = "main"
}

variable "google_project_id" {
  type = string
}

variable "google_region" {
  type = string
  default = "us-central1"
}

variable "google_domain_mapping_region" {
  type = string
  default = "us-central1"
}

variable "google_gcr_domain" {
  type = string
  default = "gcr.io"
}

variable "owner" {
  type = string
  description = "The owner of code repository"
}

variable "parsers" {
  description = "list of data parsers to configure (e.g. 'gitlab','tekton')"
  type        = list(any)
}

variable "repository" {
  type = string
  description = "The name of the git repository"
}

/*  The default for normal usage is true, because VCS webhooks need to call the endpoint over the
    public internet (with auth provided by the security token). But some deployments (including CI
    E2E tests on Google infra) will require this to be false. */
variable "make_event_handler_public" {
  description = "If true, the event handler endpoint will be accessible by unauthenticated users."
  type        = bool
  default     = true
}
