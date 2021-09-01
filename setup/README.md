> :information_source: This README is intended to replace `/setup/README.md`. 
> When it's time to promote the Terraform installer to become the preferred
> installation method (hopefully soon!), we will do the following: 
> * move the current contents of `/setup` to `/setup/deprecated`
> * move the contents of this directory to `/setup`
> * remove this note

# Installation guide

This guide describes how to set up Four Keys with your GitHub or GitLab project. The main steps are:

1.  [Running the setup script](#running-the-setup-script)
1.  Integrating with your GitHub or GitLab repo by:
    1.  [Collecting changes data](#collecting-changes-data)
    1.  [Collecting deployment data](#collecting-deployment-data)
    1.  [Collecting incident data](#collecting-incident-data)

## Before you begin

1.  Install [GCloud SDK](https://cloud.google.com/sdk/install).
1. Install [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli).
1.  You must be owner on a Google Cloud project that has billing enabled. You may either use this project to house the architecture for the Four Keys, or you will be given the option to create new projects. If you create new projects, the original Google Cloud project will NOT be altered during set up, but **the billing information from this parent project will be applied to any projects created**.


## Running the setup script

1.  Once you have your Google Cloud project, run the following setup script from the top-level directory of this repository:

    ```bash
    gcloud config set project <PARENT_PROJECT_ID>
    cd setup
    script setup.log -c ./setup.sh
    ```
1.  Answer the setup script's questions:

    *   Would you like to create a new Google Cloud Project for the four key metrics? (y/N)
        * If you choose no, you will be asked later to provide info about the project you wish to use.
    *   Choose the event sources to configure...
        *   Which version control system are you using?
            * Choose the appropriate option for your VCS, or choose "other" to skip VCS integration
        * Which CI/CD system are you using?
            * Choose the appropriate option for your CICD system, or choose "other" to skip CICD integration
        * _(see `/README.md#extending-to-other-event-sources` to integrate event sources not available during setup)_
    *   Would you like to generate mock data? (y/N)
        *   If you select yes, a script will run through and send mock GitLab or GitHub events to your event-handler.  This will populate your dashboard with mock data.  The mock data will include the work "mock" in the source. You can generate mock data without using the setup script. See [Generating mock data](../readme.md). 
            *   To exclude the mock data from the dashboard, update the SQL script to filter out any source with the word mock in it by adding: `WHERE source not like "%mock"`.

### Making changes
At some point after running the setup script, you may want to make modifications to your infrastructure. Or, the Four Keys project itself may be updated with a new configuration. Terraform can be used to apply any incremental changes: after updating the configuration files, run `terraform apply`. You'll be prompted to confirm the planned changes; review them carefully, then type `yes` to proceed.
> Tip: To make changes that will apply to your infrastructure, without editing the core configuration, consider using [Terraform Override Files](https://www.terraform.io/docs/language/files/override.html).

### New Google Cloud projects

If you've chosen to create a new Google Cloud project, after the script finishes you will have a new project with an ID in the form of `fourkeys-XXXX`. If you ever want to remove the newly created projects and all associated data, you can run `cleanup.sh`.  **Only do this when you are done experimenting with Four Keys entirely, or want to start over. Running `cleanup.sh` will remove the projects and all the collected data.**

> If you want to bulk delete many projects that you've created via the setup 
> script, all of which will be named `fourkeys-XXXX`, pass a flag to the cleanup 
> script: `./cleanup.sh -b`

### The setup explained
The setup script does many things to help create the service architecture described in the `README.md`. These include a little bash scripting and a lot of [Terraform](https://www.terraform.io/intro/).

Step by step, here's what's happening:
1. `setup.sh` starts by collecting information from the system and the user to determine a number of configuration variables that will be provided to Terraform.
1. If you choose to make a new project, `setup.sh` will use `gcloud` to create that project, with an ID in the form `fourkeys-XXXX`.
1. It sets several environment variables, and writes a `terraform.tfvars` file to disk, containing inputs to Terraform.
1. Then it invokes `install.sh`, which is responsible for provisioning the infrastructure.
1. `install.sh` runs `gcloud builds submit` commands to build the application containers that will be used in Cloud Run services.
1. Then it invokes Terraform, which processes the configuration files (ending in `.tf`) to provision all of the necessary infrastructure into the speficied Cloud project.
1. If you've chosen to generate mock data, the script then calls the ["data generator" python application](/data_generator/) to submit several synthetic webhook events to the event-handler service that was just created.
1. Finally, the script prints information about the remaining configurations, which must be done manually: adding a Data Studio dashboard and adding webhooks for VCS.

### Managing Terraform State
Terraform maintains information about infrastucture in persistent state storage, known as a backend. By default, this is maintained in a file named `terraform.tfstate`, saved to the same directory that Terraform is executed from. This local backend is fine for a one-time setup, but if you plan to maintain and use your Four Keys infrastructure, it's recommended to choose a remote backend. (Alternatively, you may choose to use Terraform only for the initial setup, and then use other tools--like `gcloud` or the Cloud Console--for ongoing modifications. That's fine.)

> To learn how to use a remote backend for robust storage of Terraform state, see: [Terraform Language: Backends](https://www.terraform.io/docs/language/settings/backends/index.html)

## Integrating with a live repo

The setup script can create mock data, but it cannot integrate automatically with live projects.  To measure your team's performance, you need to integrate to your live GitHub or GitLab repo that has ongoing deployments. You can then measure the four key metrics, and experiment with how changes, successful deployments, and failed deployments affect your metrics.

To integrate Four Keys with a live repo, you need to:

1.  [Collect changes data](#collecting-changes-data)
1.  [Collect deployment data](#collecting-deployment-data)
1.  [Collect incident data](#collecting-incident-data)

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

#### Configuring Cloud Build to deploy on GitHub Pull Request merges

1.  Go back to your repo's main page.
1.  At the top of the GitHub page, click **Marketplace**.
1.  Search for **Cloud Build**.
1.  Select **Google Cloud Build**.
1.  Click **Set Up Plan**.
1.  Click **Set up with Google Cloud Build**.
1.  Select **Only select repositories**.
1.  Fill in your forked repo.
1.  Log in to Google Cloud Platform.
1.  Add your new Four Keys project named `fourkeys-XXXXX`.
1.  Select your repo.
1.  Click **Connect repository**.
1.  Click **Create push trigger**.

And now, whenever a pull request is merged into master of your fork, Cloud Build will trigger a deploy into prod and data will flow into your Four Keys project.

#### Configuring Cloud Build to deploy on GitLab merges

1.  Go to your Four Keys project and [create a service account](https://cloud.google.com/iam/docs/creating-managing-service-accounts#iam-service-accounts-create-console) called `gitlab-deploy`.
1.  [Create a JSON service account key](https://cloud.google.com/iam/docs/creating-managing-service-account-keys#iam-service-account-keys-create-console) for your `gitlab-deploy` service account.
1.  In your GitLab repo, navigate to `Settings` on the left-hand menu and then select `CI/CD`.
1.  Save your account key under variables.
    1.  In the **key** field, input `SERVICE_ACCOUNT`.
    1.  In the **Value** field, input the JSON . 
    1.  Select **Protect variable**.
1.  Save your Google Cloud project-id under variables.
    1.  In the **key** field, input `PROJECT_ID`.
    1.  In the **value** field, input your `project-id`.
1.  Add a `.gitlab-ci.yml` file to your repo.
    ```
    image: google/cloud-sdk:alpine

    deploy_production:
      stage: deploy
      environment: Production
      only:
      - master
      script:
      - echo $SERVICE_ACCOUNT > /tmp/$CI_PIPELINE_ID.json
      - gcloud auth activate-service-account --key-file /tmp/$CI_PIPELINE_ID.json
      - gcloud builds submit . --project $PROJECT_ID
      after_script:
      - rm /tmp/$CI_PIPELINE_ID.json
    ```

This setup will trigger a deployment on any `push` to the `master` branch.

### Collecting incident data

Four Keys uses GitLab and/or GitHub issues to track incidents.  

#### Creating an incident

1.  Open an issue.
1.  Add the tag `Incident`.
1.  In the body of the issue, input `root cause: {SHA of the commit}`.

When the incident is resolved, close the issue. Four Keys will measure the incident from the time of the deployment to when the issue is closed.
