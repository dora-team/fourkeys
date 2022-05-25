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
| <a name="module_bigquery"></a> [bigquery](#module\_bigquery) | ../fourkeys-bigquery | n/a |
| <a name="module_cloud_build_parser"></a> [cloud\_build\_parser](#module\_cloud\_build\_parser) | ../fourkeys-cloud-build-parser | n/a |
| <a name="module_dashboard"></a> [dashboard](#module\_dashboard) | ../fourkeys-dashboard | n/a |
| <a name="module_foundation"></a> [foundation](#module\_foundation) | ../fourkeys-foundation | n/a |
| <a name="module_fourkeys_images"></a> [fourkeys\_images](#module\_fourkeys\_images) | ../fourkeys-images | n/a |
| <a name="module_github_parser"></a> [github\_parser](#module\_github\_parser) | ../fourkeys-github-parser | n/a |
| <a name="module_gitlab_parser"></a> [gitlab\_parser](#module\_gitlab\_parser) | ../fourkeys-gitlab-parser | n/a |
| <a name="module_tekton_parser"></a> [tekton\_parser](#module\_tekton\_parser) | ../fourkeys-tekton-parser | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bigquery_region"></a> [bigquery\_region](#input\_bigquery\_region) | Region to deploy BigQuery resources in. | `string` | `"US"` | no |
| <a name="input_dashboard_container_url"></a> [dashboard\_container\_url](#input\_dashboard\_container\_url) | If 'enable\_build\_images' is set to false, this is the URL for the dashboard container image. | `string` | `""` | no |
| <a name="input_enable_apis"></a> [enable\_apis](#input\_enable\_apis) | Toggle to include required APIs. | `bool` | `false` | no |
| <a name="input_enable_build_images"></a> [enable\_build\_images](#input\_enable\_build\_images) | Toggle to build fourkeys images and upload to container registry. If set to false, URLs for images must be provided via the container\_url variables | `bool` | `true` | no |
| <a name="input_event_handler_container_url"></a> [event\_handler\_container\_url](#input\_event\_handler\_container\_url) | If 'enable\_build\_images' is set to false, this is the URL for the event\_handler container image. | `string` | `""` | no |
| <a name="input_parser_container_urls"></a> [parser\_container\_urls](#input\_parser\_container\_urls) | If 'enable\_build\_images' is set to false, this is the URL for the parser container images. e.g: {'github': 'gcr.io/youproject/github-parser', 'gitlab': 'gcr.io/youproject/gitlab-parser'} | `map(any)` | `{}` | no |
| <a name="input_parsers"></a> [parsers](#input\_parsers) | List of data parsers to configure. Acceptable values are: 'github', 'gitlab', 'cloud-build', 'tekton' | `list(string)` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | project to deploy four keys resources to | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region to deploy fource keys resources in. | `string` | `"us-central1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dashboard_endpoint"></a> [dashboard\_endpoint](#output\_dashboard\_endpoint) | n/a |
| <a name="output_event_handler_endpoint"></a> [event\_handler\_endpoint](#output\_event\_handler\_endpoint) | n/a |
| <a name="output_event_handler_secret"></a> [event\_handler\_secret](#output\_event\_handler\_secret) | n/a |