variable "google_project_id" {
  type = string
}

variable "google_region" {
  type = string
}

variable "bigquery_region" {
  type = string
  validation {
    condition = (
      contains(["US", "EU"], var.bigquery_region)
    )
    error_message = "The value for 'bigquery_region' must be one of: 'US','EU'."
  }
}

variable "parsers" {
  type        = list(any)
  description = "list of data parsers to configure (e.g. 'gitlab','tekton')"
}

/*  The default for normal usage is true, because VCS webhooks need to call the endpoint over the
    public internet (with auth provided by the security token). But some deployments (including CI
    E2E tests on Google infra) will require this to be false. */
variable "make_event_handler_public" {
  type        = bool
  default     = true
  description = "If true, the event handler endpoint will be accessible by unauthenticated users."
}