# Grafana Dashboard

[Grafana](https://grafana.com) is an open source dashboard.  The Four Keys project is using it to display the four key metrics.  

## Current configuration
You can see the configuration of the Grafana image in the `Dockerfile`.  

### Authentication
Auth is currently disabled by default. Learn more about [Grafana User Authentication](https://grafana.com/docs/grafana/latest/auth/). To require a login, delete or comment out these lines: 

```
ENV GF_AUTH_DISABLE_LOGIN_FORM "true"
ENV GF_AUTH_ANONYMOUS_ENABLED "true"
ENV GF_AUTH_ANONYMOUS_ORG_ROLE "Admin"
```

Then update `grafana.ini` with the auth configuration of your choice.

### Provisioning
The datasource and dashboard are configured in `datasource.yaml` and `dashboards.yaml`.  Learn more about provisioning [here](https://grafana.com/docs/grafana/latest/administration/provisioning/). 

## How to update the dashboard
The dashboard is running in a transient container. It does not store data.  Therefore, if you want to update the dashboard, you must update the `fourkeys_dashboard.json`.  The easiest way to update the JSON is to make changes in the UI and export the JSON.  *Any changes in the UI will be temporary and must be saved in the container image.*  

1.  Update the dashboard in the UI
1.  Export the JSON
1.  Save the JSOn in fourkeys_dashboard.json
1.  Re-build the image and re-deploy the container

To rebuild and deploy the container, you can run `gcloud builds submit` in this directory. 


## To deploy dashboard
If using [Terraform](https://www.terraform.io), please see the [setup](setup/) to create the resources.  

Once the resource is created or if you are not using Terraform, feel free to build and deploy outside of Terraform by running `gcloud builds submit` in this directory. 
