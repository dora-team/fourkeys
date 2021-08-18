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
  type        = string
  description = "(optional) the branch to trigger event handler and bq worker builds"
  default     = "main"
}

variable "google_project_id" {
  type = string
}

variable "google_region" {
  type    = string
  default = "us-central1"
}

variable "google_dns" {
  description = "To create a Google Cloud DNS zone and records for event handler"
  default     = false
  type        = bool
}

variable "google_domain_mapping_region" {
  type        = string
  description = "Domain mapping region"
  default     = "us-central1"
  validation {
    condition = (
      !contains([
        "asia-east2",
        "asia-northeast2",
        "asia-northeast3",
        "asia-southeast2",
        "asia-south1",
        "asia-south2",
        "australia-southeast1",
        "australia-southeast2",
        "europe-central2",
        "europe-west2",
        "europe-west3",
        "europe-west6",
        "northamerica-northeast1",
        "northamerica-northeast2",
        "southamerica-east1",
        "us-west2",
        "us-west3",
        "us-west4",
      ], var.google_domain_mapping_region)
    )
    error_message = "The value for 'google_domain_mapping_region' is invalid, check https://cloud.google.com/run/docs/locations#domains ."
  }
}

variable "google_gcr_domain" {
  type    = string
  default = "gcr.io"
}

variable "looker_service_account" {
  description = "To create a service account for Looker (dashboard)"
  default     = false
  type        = bool
}

variable "mapped_domain" {
  type        = string
  description = "Domain name which is mapped on cloud run."
  default     = ""
}

/*  The default for normal usage is true, because VCS webhooks need to call the endpoint over the
    public internet (with auth provided by the security token). But some deployments (including CI
    E2E tests on Google infra) will require this to be false. */
variable "make_event_handler_public" {
  description = "If true, the event handler endpoint will be accessible by unauthenticated users."
  type        = bool
  default     = true
}

variable "owner" {
  type        = string
  description = "The owner of code repository"
}

variable "parsers" {
  description = "list of data parsers to configure (e.g. 'gitlab','tekton')"
  type        = list(any)
}

variable "repository" {
  type        = string
  description = "The name of the git repository"
}

variable "service_account_keys_policy_override" {
  description = "To override organisation service account keys creation policy for project"
  default     = false
  type        = bool
}

variable "subdomain" {
  description = "The prefix added to the `mapped_domain`, of event handler, use to create a record within Google Cloud DNS."
  default     = "dora"
  type        = string
}
