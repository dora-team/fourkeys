## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_cloud_run_service.github_parser](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service) | resource |
| [google_project_iam_member.pubsub_service_account_token_creator](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.data_source_services](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_pubsub_subscription.github](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription) | resource |
| [google_pubsub_topic.github](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | resource |
| [google_pubsub_topic_iam_member.service_account_editor](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_apis"></a> [enable\_apis](#input\_enable\_apis) | Toggle to include required APIs. | `bool` | `false` | no |
| <a name="input_fourkeys_service_account_email"></a> [fourkeys\_service\_account\_email](#input\_fourkeys\_service\_account\_email) | Service account for fourkeys. | `string` | n/a | yes |
| <a name="input_parser_container_url"></a> [parser\_container\_url](#input\_parser\_container\_url) | URL of image to use in Cloud Run service configuration. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project ID of the target project. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region to deploy resources. | `string` | `"us-central1"` | no |

## Outputs

No outputs.