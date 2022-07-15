# Installation guide

This guide describes how to set up Four Keys with your GitHub or GitLab project. The main steps are:

1. Forking this repository
1. Providing values for required Terraform variables
1. Executing Terraform to deploy resources
1. Generating sample data (optional)
1. Integrating your repository to send data to your Four Keys deployment.

> Alternatively, to deploy Four Keys as a remote Terraform module, see `terraform/modules/fourkeys/README.md`

## Before you begin

To deploy Four Keys with Terraform, you will first need:

* A Google Cloud project with billing enabled
* The owner role assigned to you on the project
* The [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) and [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed on your local machine. We recommend deploying from [Cloud Shell](https://shell.cloud.google.com/?show=ide%2Cterminal) on your Google Cloud project.

## Deploying with Terraform

1. Clone the fourkeys git repository, or copy the files in the `terraform/example` directory to your working directory

1. Rename `terraform.tfvars.example` to `terraform.tfvars`

1. Edit `terraform.tfvars` with values for the required variables. See `variables.tf` for a list of the variables, along with their descriptions and default values. To accept the default value of a variable indicated in `variables.tf`, exclude it from `terraform.tfvars`

1. Run the following commands from the `example` directory, or your working directory:

    `terraform init` to inialize Terraform and download the module

    `terraform plan` to preview changes.

    `terraform apply` to deploy the resources.


## Generating mock data

To test your Four Keys deployment, you can generate mock data that simulates events from a Github repository.  

1. Export your event handler URL an environment variable. This the webhook URL that will receive events:

    ```sh
    export WEBHOOK=`gcloud run services list | grep event-handler | awk '{print $4}'`
    ```

1. Export your event handler secret to an environment variable. This is the secret used to authenticate events sent to the webhook:

    ```sh
    export SECRET=`gcloud secrets versions access 1 --secret=event-handler`
    ```

1. From the root of the fourkeys project run:

    ```sh
    python3 data_generator/generate_data.py --vc_system=github
    ```

    You can see these events being run through the pipeline:
    * The event handler logs show successful requests
    * The Pub/Sub topic show messages posted
    * The BigQuery GitHub parser show successful requests

1. View the generated data in the `events_raw` table in with bq:

    ```sh
    bq query 'SELECT * FROM four_keys.events_raw WHERE source = "githubmock";'
    ```

    Or query the table directly in [BigQuery](https://console.cloud.google.com/bigquery):

    ```sql
    SELECT * FROM four_keys.events_raw WHERE source = 'githubmock';
    ```

## Integrating with a live repo
To measure your team's performance, you need to integrate to your live GitHub or GitLab repo that has ongoing deployments. You can then measure the four key metrics, and experiment with how changes, successful deployments, and failed deployments affect your metrics.

To integrate Four Keys with a live repo, you need to:

1.  [Collect changes data](#collecting-changes-data)
1.  [Collect deployment data](#collecting-deployment-data)
1.  [Collect incident data](#collecting-incident-data)