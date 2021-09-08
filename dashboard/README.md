# Grafana Dashboard

[Grafana](https://grafana.com) is an open source dashboard.  The Four Keys project is using it to display the four key metrics.  

## Current configuration
You can see the configuration of the Grafana image in the `Dockerfile`.  Auth is currently disabled by default. Enable it by deleting or commenting out these lines:

```
ENV GF_AUTH_DISABLE_LOGIN_FORM "true"
ENV GF_AUTH_ANONYMOUS_ENABLED "true"
ENV GF_AUTH_ANONYMOUS_ORG_ROLE "Admin"
```

The datasource and dashboard are configured in `datasource.yaml` and `dashboards.yaml`.  Learn more about provisioning [here](https://grafana.com/docs/grafana/latest/administration/provisioning/). 

## How to update the dashboard
The dashboard is running in a transient container. It does not store data.  Therefore, if you want to update the dashboard, you must update the `fourkeys_dashboard.json`, rebuild the image, and re-deploy the container.  The `cloudbuild.yaml` contains the steps to do this, which you can invoke with `gcloud builds submit`. 

## To deploy dashboard
If using [Terraform](https://www.terraform.io), please see the [setup](setup/) to create the resources.  

Once the resource is created or if you are not using Terraform, feel free to build and deploy outside of Terraform by running `gcloud builds submit` in this directory. 
