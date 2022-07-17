# Four Keys Terraform

🚧 **This Terraform is still under developement and may be missing some resources that would be deployed with [`setup.sh`](https://github.com/GoogleCloudPlatform/fourkeys/blob/main/setup/setup.sh)**

This directory contains modules and examples for deploying Four Keys with Terraform. The primary module `modules/fourkeys` uses the other sub-modules to deploy resources to a provided Google Cloud Project.  

## Usage

This is an example of deploying fourkeys as a remote Terraform module from [this GitHub project](https://github.com/GoogleCloudPlatform/fourkeys):

```hcl
module "fourkeys" {
  source    = "github.com/GoogleCloudPlatform/fourkeys//terraform/modules/fourkeys"
  project_id = "your-google-cloud-project-id"
  parsers   = ['github']
}
```

The example above will deploy Four Keys with a Github parser for Github events. See the `terraform/example` directory for full example and options.

Alternatively, you can fork the fourkeys project and deploy as a local module from the `terraform/example` directory:

```hcl
module "fourkeys" {
  source    = "../modules/fourkeys"
  project_id = "your-google-cloud-project-id"
  parsers   = ['github']
}
```

## Before you begin

To deploy Four Keys with Terraform, you will first need:

* A Google Cloud project with billing enabled
* The owner role assigned to you on the project
* The [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) and [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed on your local machine. We recommend deploying from [Cloud Shell](https://shell.cloud.google.com/?show=ide%2Cterminal) on your Google Cloud project.

## Deploying with Terraform
#TODO: Replace step 1 with rewrite
1. Terraform will presume that the project you're using will have the relavant images in the container registry. Build the following:
    - dashboard
    - event handler
    - parsers you plan on using

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
    python3 data-generator/generate_data.py --vc_system=github
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
## Updating Cloud Run Services 
TODO: replace/rewrite

When an image is updated in your project's container, run the following to recreate the corresponding Cloud Run Service via gcloud:
``sh
gcloud run services update RUNSERVICENAME --image gcr.io/cloudbuild-fio-b549/<image>:latest
``
