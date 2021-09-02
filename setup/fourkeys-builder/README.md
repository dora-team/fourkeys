This folder contains a Dockerfile to make a builder container for use 
in Cloud Build... the container has gcloud, python 3, and Terraform installed,
all of which are needed to install and test Four Keys.

Before using this in Cloud Build, publish the builder to your GCP project, by running the following command in this folder:

```
gcloud builds submit -t gcr.io/$(gcloud config list project --format="value(core.project)")/fourkeys-builder
```