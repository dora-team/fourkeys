## Usage
Deploy FourKeys with Github parser and default values:

```hcl
module "fourkeys" {
  source    = "github.com/GoogleCloudPlatform/fourkeys//terraform/modules/fourkeys"
  project_id = "your-google-cloud-project-id"
  parsers   = ['github']
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.17.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_circleci_parser"></a> [circleci\_parser](#module\_circleci\_parser) | ../fourkeys-circleci-parser | n/a |
| <a name="module_cloud_build_parser"></a> [cloud\_build\_parser](#module\_cloud\_build\_parser) | ../fourkeys-cloud-build-parser | n/a |
| <a name="module_fourkeys_images"></a> [fourkeys\_images](#module\_fourkeys\_images) | ../fourkeys-images | n/a |
| <a name="module_github_parser"></a> [github\_parser](#module\_github\_parser) | ../fourkeys-github-parser | n/a |
| <a name="module_gitlab_parser"></a> [gitlab\_parser](#module\_gitlab\_parser) | ../fourkeys-gitlab-parser | n/a |
| <a name="module_pagerduty_parser"></a> [pagerduty\_parser](#module\_pagerduty\_parser) | ../fourkeys-pagerduty-parser | n/a |
| <a name="module_tekton_parser"></a> [tekton\_parser](#module\_tekton\_parser) | ../fourkeys-tekton-parser | n/a |

## Resources

| Name | Type |
|------|------|
| [google_bigquery_dataset.four_keys](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset) | resource |
| [google_bigquery_dataset_iam_member.parser_bq](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset_iam_member) | resource |
| [google_bigquery_routine.func_json2array](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_routine) | resource |
| [google_bigquery_routine.func_multiFormatParseTimestamp](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_routine) | resource |
| [google_bigquery_table.events_raw](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_table) | resource |
| [google_bigquery_table.view_changes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_table) | resource |
| [google_bigquery_table.view_deployments](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_table) | resource |
| [google_bigquery_table.view_incidents](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_table) | resource |
| [google_cloud_run_service.dashboard](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service) | resource |
| [google_cloud_run_service.event_handler](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service) | resource |
| [google_cloud_run_service_iam_binding.dashboard_noauth](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service_iam_binding) | resource |
| [google_cloud_run_service_iam_binding.event_handler_noauth](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service_iam_binding) | resource |
| [google_project_iam_member.bigquery_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.cloud_run_invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.parser_bq_project_access](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.parser_run_invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.storage_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.fourkeys_services](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_secret_manager_secret.event_handler](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret_iam_member.event_handler](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_secret_manager_secret_version.event_handler](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [google_service_account.fourkeys](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [random_id.event_handler_random_value](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bigquery_region"></a> [bigquery\_region](#input\_bigquery\_region) | Region to deploy BigQuery resources in. | `string` | `"US"` | no |
| <a name="input_dashboard_container_url"></a> [dashboard\_container\_url](#input\_dashboard\_container\_url) | If 'enable\_build\_images' is set to false, this is the URL for the dashboard container image. | `string` | `""` | no |
| <a name="input_enable_apis"></a> [enable\_apis](#input\_enable\_apis) | Toggle to include required APIs. | `bool` | `false` | no |
| <a name="input_enable_build_images"></a> [enable\_build\_images](#input\_enable\_build\_images) | Toggle to build fourkeys images and upload to container registry. If set to false, URLs for images must be provided via the container\_url variables | `bool` | `true` | no |
| <a name="input_event_handler_container_url"></a> [event\_handler\_container\_url](#input\_event\_handler\_container\_url) | If 'enable\_build\_images' is set to false, this is the URL for the event\_handler container image. | `string` | `""` | no |
| <a name="input_parser_container_urls"></a> [parser\_container\_urls](#input\_parser\_container\_urls) | If 'enable\_build\_images' is set to false, this is the URL for the parser container images. e.g: {'github': 'gcr.io/youproject/github-parser', 'gitlab': 'gcr.io/youproject/gitlab-parser'} | `map(any)` | `{}` | no |
| <a name="input_parsers"></a> [parsers](#input\_parsers) | List of data parsers to configure. Acceptable values are: 'github', 'gitlab', 'cloud-build', 'tekton', 'circleci', 'pagerduty' | `list(string)` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | project to deploy four keys resources to | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region to deploy fource keys resources in. | `string` | `"us-central1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dashboard_endpoint"></a> [dashboard\_endpoint](#output\_dashboard\_endpoint) | n/a |
| <a name="output_event_handler_endpoint"></a> [event\_handler\_endpoint](#output\_event\_handler\_endpoint) | n/a |
| <a name="output_event_handler_secret"></a> [event\_handler\_secret](#output\_event\_handler\_secret) | n/a |
| <a name="output_fourkeys_service_account_email"></a> [fourkeys\_service\_account\_email](#output\_fourkeys\_service\_account\_email) | n/a |
