# Installation Guide

## Getting Started

Getting started using FourKeys is relatively simple.  You will need a few tools installed:
#### Requirements
- [GCloud SDK](https://cloud.google.com/sdk/install)

You will also need to be owner on a GCP project that has billing enabled.  This project will NOT be altered during set up, but the billing information from this parent project will be applied to the 2 projects we created.

Once you have your parent project just do the following:
```bash
gcloud config set project $PARENT_PROJECT_ID
./setup.sh 2>&1 | tee setup.log
```

After the script finishes you will have two new projects named in the env.sh file of the form 'fourkeys-XXXX' and 'hs-XXXXX'.  The fourkeys-XXXX project will be home to all the services that collect data from your deployments, while hs-XXXX will be the staging and prod deployments for your application.

Later if you want to remove the newly created projects and all associated data, you can run the cleanup.sh.  **Only do this when you are done experimenting with fourkeys entirely, or want to start over because cleanup.sh will remove the projects and all the collected data.**

## The Setup Explained
The setup script is going to do many things to help create the service architecture described in the README.md.  The script will output the commands you would need to do manually.

The steps are:
- Create randomly generated project names
- Save project names in env.sh
- Set up Four Keys Project
  - Create project
  - Link billing to parent project
  - Enable Apis
  - Add IAM Policy Bindings
  - Create PubSub Topics
  - Deploy Event Handler
  - Deploy BigQuery Github Worker
  - Deploy BigQuery Cloud Build Worker
  - Create BigQuery PubSub Subscriptions
  - Create BigQuery Dataset, Tables, and Scheduled Queries
- Set up Hipster Store Project
  - Create Project
  - Link billing to parent project
  - Enable Apis
  - Create Kubernetes Clusters
  - Configure Container Registry Auth
  - Clone Hipster Store (microservices-demo) 
  - Patch skaffold version
  - Deploy HS to staging
  - Deploy HS to prod
  - Add dummy data to FourKeys BigQuery


## How To Configure A Live Repo

So now that we've seen what the project looks like with dummy data, it would be good to hook up the services to a live repo with ongoing deployments so we can experiment with how changes, successful deployments, and failed deployments affect our statistics.

Doing this will require a few extra manual steps:

#### Configure Hipster Store project to send data to project
- Fork the Hipster Store demo repo by navigating to the [Github Repo](https://github.com/GoogleCloudPlatform/microservices-demo) and clicking 'Fork'.
- Now that it is forked, navigate to your fork and click 'Settings.'
- Select 'Webhooks' from the left hand side.
- Click 'Add Webhook'
- Get the Event Handler endpoint for your Four Keys service:
```bash
. ./env.sh
gcloud config set project ${FOURKEYS_PROJECT}
gcloud run --platform managed --region ${FOURKEYS_REGION} services describe event-handler --format=yaml | grep url | head -1 | sed -e 's/  *url: //g'
```
- In the 'Add Webhook' interface use the Event Handler endpoint for 'Payload URL'
- Run the following command to get the secret from Google Secrets Manager
```bash
gcloud secrets versions access 1 --secret="github-secret"
```
- Put the secret in the box labelled 'Secret'
- Select 'application/json' for 'Content Type'
- Select 'Send me everything'
- Finish with clicking 'Add Webhook'

#### Configuring Cloud Build to deploy on PR merges
- Go back to your forked repo's main page
- At the top of the Github page, click 'Marketplace'
- Search for 'Cloud Build'
- Select 'Google Cloud Build'
- Click 'Set Up Plan'
- Click 'Set up with Google Cloud Build'
- Select 'Only select repositories'
- Fill in your forked microservices-demo repo
- Log in to Google Cloud Platform
- Add your new FourKeys project named fourkeys-XXXXX
- Select your repo
- Click 'Connect repository'
- Click 'Create push trigger'

And now, whenever a pull request is merged into master of your fork, Cloud Build will trigger a deploy into prod and data will flow into your Four Keys project.

## How To Configure For Your Own Repo

To use this project with your own repo, it is a relatively simple matter of repeating the steps above, but instead of configuring the Hipster Store demo repo to send data, configure it against your own repo.