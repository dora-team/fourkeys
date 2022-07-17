## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gcloud_build_dashboard"></a> [gcloud\_build\_dashboard](#module\_gcloud\_build\_dashboard) | terraform-google-modules/gcloud/google | ~> 2.0 |
| <a name="module_gcloud_build_data_source"></a> [gcloud\_build\_data\_source](#module\_gcloud\_build\_data\_source) | terraform-google-modules/gcloud/google | ~> 2.0 |
| <a name="module_gcloud_build_event_handler"></a> [gcloud\_build\_event\_handler](#module\_gcloud\_build\_event\_handler) | terraform-google-modules/gcloud/google | ~> 2.0 |

## Resources

| Name | Type |
|------|------|
| [google_project_service.images_services](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_apis"></a> [enable\_apis](#input\_enable\_apis) | Toggle to include required APIs. | `bool` | `false` | no |
| <a name="input_parsers"></a> [parsers](#input\_parsers) | List of data parsers to configure. Acceptable values are: 'github', 'gitlab', 'cloud-build', 'tekton' | `list(string)` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | n/a | `string` | n/a | yes |

## Outputs

No outputs.