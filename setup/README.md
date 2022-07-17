# Installation guide

This guide describes how to set up Four Keys with your GitHub or GitLab project. The main steps are:

1.  [Running the setup script](#running-the-setup-script)
1.  Integrating with your GitHub or GitLab repo by:
    1.  [Collecting changes data](#collecting-changes-data)
    1.  [Collecting deployment data](#collecting-deployment-data)
    1.  [Collecting incident data](#collecting-incident-data)

## Before you begin
> We recommend using [Cloud Shell](https://cloud.google.com/shell) to install Four Keys
1. Install [GCloud SDK](https://cloud.google.com/sdk/install).
1. Install [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli).
1. You must be owner on a Google Cloud project that has billing enabled. You can either use a currently active project or create a new project specifically to use with Four Keys.

> :information_source: To create a new project using the same billing account as your currently-active gcloud project, run the following commands:
> ```sh
> export PARENT_PROJECT=$(gcloud config get-value project)
> export PARENT_FOLDER=$(gcloud projects describe ${PARENT_PROJECT} --format="value(parent.id)")
> export BILLING_ACCOUNT=$(gcloud beta billing projects describe ${PARENT_PROJECT} --format="value(billingAccountName)")
> export FOURKEYS_PROJECT=$(printf "fourkeys-%06d" $((RANDOM%999999)))
> gcloud projects create ${FOURKEYS_PROJECT} --folder=${PARENT_FOLDER}
> gcloud beta billing projects link ${FOURKEYS_PROJECT} --billing-account=${BILLING_ACCOUNT}
> echo "project created: "$FOURKEYS_PROJECT
> 
> ```


## Running the setup script

1.  Run the following setup script from the top-level directory of this repository:

    ```bash
    cd setup
    script setup.log -c ./setup.sh
    ```
1.  Answer the setup script's questions:

    *   Enter the project ID and region information for the project in which you wish to install Four Keys
    *   Choose the event sources to configure...
        *   Which version control system are you using?
            * Choose the appropriate option for your VCS, or choose "other" to skip VCS integration
        * Which CI/CD system are you using?
            * Choose the appropriate option for your CICD system, or choose "other" to skip CICD integration
        * _(see `/README.md#extending-to-other-event-sources` to integrate event sources not available during setup)_
    *   Would you like to generate mock data? (y/N)
        *   If you select yes, a script will run through and send mock GitLab or GitHub events to your event-handler.  This will populate your dashboard with mock data.  The mock data will include the work "mock" in the source. You can generate mock data without using the setup script. See [Generating mock data](../README.md). 
            *   To exclude the mock data from the dashboard, update the SQL script to filter out any source with the word mock in it by adding: `WHERE source not like "%mock"`.

### Making changes
At some point after running the setup script, you may want to make modifications to your infrastructure. Or, the Four Keys repo itself may be updated with a new configuration. If you make changes to your resources outside of Terraform, they will not be tracked and cannot be managed by Terraform. This includes pub/sub topics, subscriptions, permissions, service accounts, services, etc. Therefore, it's recommended to make all infrastructure changes by updating your Terraform files and re-running Terraform, using `terraform apply`. You'll be prompted to confirm the planned changes; review them carefully, then type `yes` to proceed.
> Tip: The configurations in this repo will continue to evolve over time; if you want to be able to apply ongoing updates, **don't modify the tracked Terraform files**. Instead, consider using [Terraform Override Files](https://www.terraform.io/docs/language/files/override.html), which will allow you to customize the infrastructure to your needs without introducing potential merge conflicts the next time you pull from upstream.

### The setup explained
The setup script does many things to help create the service architecture described in the `README.md`. These include a little bash scripting and a lot of [Terraform](https://www.terraform.io/intro/).

Step by step, here's what's happening:
1. `setup.sh` starts by collecting information from the system and the user to determine a number of configuration variables that will be provided to Terraform.
1. It sets several environment variables, and writes a `terraform.tfvars` file to disk, containing inputs to Terraform.
1. Then it invokes `install.sh`, which is responsible for provisioning the infrastructure.
1. `install.sh` runs `gcloud builds submit` commands to build the application containers that will be used in Cloud Run services.
1. Then it invokes Terraform, which processes the configuration files (ending in `.tf`) to provision all of the necessary infrastructure into the speficied Cloud project.
1. If you've chosen to generate mock data, the script then calls the ["data generator" python application](/data-generator/) to submit several synthetic webhook events to the event-handler service that was just created.
1. Finally, the script prints information about next steps, including configuring webhooks and visiting the dashboard.

### Managing Terraform State
Terraform maintains information about infrastucture in persistent state storage, known as a backend. By default, this is maintained in a file named `terraform.tfstate`, saved to the same directory that Terraform is executed from. This local backend is fine for a one-time setup, but if you plan to maintain and use your Four Keys infrastructure, it's recommended to choose a remote backend. (Alternatively, you may choose to use Terraform only for the initial setup, and then use other tools--like `gcloud` or the Cloud Console--for ongoing modifications.)

> To learn how to use a remote backend for robust storage of Terraform state, see: [Terraform Language: Backends](https://www.terraform.io/docs/language/settings/backends/index.html)

### Purging resources created by Terraform
If something goes wrong during Terraform setup, you may be able to run `terraform destroy` to delete the resources that were created. However, it's possible for the Terraform state to become inconsistent with your project, leaving Terraform unaware of resources (yet their existance will prevent subsequent installations from working). If that happens, the best option is usually to delete the GCP project and start a new one. If that's not possible, you can force-remove all of the four keys resources in your project by running:
```shell
./ci/project_cleaner.sh --project=<your_fourkeys_project>
```

## Integrating with a live repo
The setup script can create mock data, but it cannot integrate automatically with live projects.  To measure your team's performance, you need to integrate to your live GitHub or GitLab repo that has ongoing deployments. You can then measure the four key metrics, and experiment with how changes, successful deployments, and failed deployments affect your metrics.

To integrate Four Keys with a live repo, you need to:

1.  [Collect changes data](#collecting-changes-data)
1.  [Collect deployment data](#collecting-deployment-data)
1.  [Collect incident data](#collecting-incident-data)

## Migrating from an earlier version of The Four Keys
If you have an existing installation of The Four Keys, created using the now-deprecated [bash-based setup process](deprecated/), and you want to be able to keep your installation up-to-date with new upstream releases, you'll need to put your cloud resources under Terraform control. The easiest way to do this is to destroy all existing resources and let Terraform create new ones that it will then manage going forward. Here's the process to do that (adapt as needed for your specific installation):
1. [Export the data](https://cloud.google.com/bigquery/docs/exporting-data#console) from `events_raw`
    * _If you exported your data to a bucket in a project that you plan to delete, be sure to download it before deleting the project!_
1. Delete existing cloud resources
    * If you have a project dedicated to Four Keys, you can simply delete that project
1. Run `setup.sh` in this folder
    * When configuring the installation, choose to not generate mock data
1. When the setup is complete: 
    1. Use the newly-generated webhook URL and secret to reconfigure webhook deliveries from your VCS/CICD systems
    1. Import the `events_raw` data:
        1. [Load the data into a temporary table](https://cloud.google.com/bigquery/docs/loading-data-cloud-storage-csv#console) named `events_raw_import`
            * You may need to manually specify the schema (and delete the column headers) when importing
        1. Copy the imported data into the `events_raw` table 
            * `INSERT INTO events_raw (SELECT * FROM events_raw_import)`
        1. Delete the temporary table

### Collecting changes data

#### GitHub instructions

1.  Start with your GitHub repo
1.  Navigate to your repo (or forked repo) and click **Settings**.
1.  Select **Webhooks** from the left hand side.
1.  Click **Add Webhook**.
1.  Get the Event Handler endpoint for your Four Keys service:
    ```bash
    echo $(terraform output -raw event_handler_endpoint)
    ```
1.  In the **Add Webhook** interface use the Event Handler endpoint for **Payload URL**.
1.  Run the following command to get the secret from Google Secrets Manager:
    ```bash
    echo $(terraform output -raw event_handler_secret)
    ```
1.  Put the secret in the box labelled **Secret**.
1.  For **Content Type**, select **application/json**.
1.  Select **Send me everything**.
1.  Click **Add Webhook**.

#### GitLab instructions

1.  Navigate to your repo and click **Settings**.
1.  Select **Webhooks** from the menu.
1.  Get the Event Handler endpoint for your Four Keys service by running the following:
    ```bash
    echo $(terraform output -raw event_handler_endpoint)
    ```
1.  For **Payload URL**, use the Event Handler endpoint.
1.  Run the following command to get the secret from Google Secrets Manager:
    ```bash
    echo $(terraform output -raw event_handler_secret)
    ```
1.  Put the secret in the box labelled **Secret Token**.
1.  Select all the checkboxes.
1.  Leave the **Enable SSL verification** selected.
1.  Click **Add Webhook**.

### Collecting deployment data

1.  For whichever CI/CD system you are using, set it up to send Webhook events to the event-handler.  

#### Configuring CircleCI to deploy on GitHub or Gitlab merges
                             
1.  Add a `.circleci.yaml` file to your repo.
    ```
    version: 2.1
    executors:
      default:
        ...
    jobs:
      build:
        executor: default
        steps:
          - run: make build
      deploy:
        executor: default
        steps:
          - run: make deploy
    workflows:
      version: 2
      build_and_deploy_on_master: # A workflow whose name contains 'deploy' will be used in the query to build the deployments view
        jobs:
          - build:
              name: build
              filters: &master_filter
                branches:
                  only: master
          - deploy:
              name: deploy
              filters: *master_filter
              requires:
                - build
    ```
 
This setup will trigger a deployment on any `push` to the `master` branch.

### Collecting incident data

Four Keys uses GitLab and/or GitHub issues to track incidents.  

#### Creating an incident

1.  Open an issue.
1.  Add the tag `Incident`.
1.  In the body of the issue, input `root cause: {SHA of the commit}`.

When the incident is resolved, close the issue. Four Keys will measure the incident from the time of the deployment to when the issue is closed.

#### Pager Duty Support
If Pager Duty support is enabled (passed via the `parsers` variable), this secret is required and used for verifying Pager Duty events received belong to us.

To create this secret:

1. You will need a [Pager Duty General Access REST API Key](https://support.pagerduty.com/docs/api-access-keys#section-generate-a-general-access-rest-api-key). These can only be created by users that are >=Global Admin.
2. Using said API key, [create a webhook subscription](https://developer.pagerduty.com/api-reference/b3A6MjkyNDc4NA-create-a-webhook-subscription). The example below creates an account-wide subscription, but depending on your Four Keys architecture, you could choose to create individual subscriptions per-project or service.

```
API_TOKEN=<your_api_token>
FOURKEYS_ENDPOINT=<your_fourkeys_endpoint>
curl-- location-- request POST
  'https://api.pagerduty.com/webhook_subscriptions'-- header
  'Authorization: Token token=${API_TOKEN}'-- header
  'Content-Type: application/json'-- header
  'Accept: application/vnd.pagerduty+json;version=2'-- data - raw '{
    "webhook_subscription": {
      "delivery_method": {
        "type": "http_delivery_method",
        "url": "${FOURKEYS_ENDPOINT}"
      },
      "description": "Sends PagerDuty v3 webhook events to DORA metrics.",
      "events": [
        "incident.resolved",
        "incident.triggered"
      ],
      "filter": {
        "type": "account_reference"
      },
      "type": "webhook_subscription"
    }
  }'
```

3. The Pager Duty webhook subscription creation API response will include a secret (_only_ returned on creation). This secret needs to be stored in Secret Manager in your Four Keys project as `pager_duty_secret`.

```
SECRET=<your_pager_duty_secret>
echo $SECRET | tr -d '\n' | gcloud beta secrets create pager_duty_secret \
    --replication-policy=automatic \
    --data-file=-
```
