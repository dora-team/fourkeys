

## Using tfsate remote

Add the code snippet below in the [file](https://github.com/GoogleCloudPlatform/fourkeys/blob/main/terraform/example/main.tf), enabling the sending of 'remote tfstate' to GCP.

```
terraform {
  backend "gcs" {
    bucket = "[project-id]-bucket-tfstate"
    prefix = "terraform/state"
  }
}
```


In the `google_storage_bucket` is used variable `uniform_bucket_level_access` [doc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket#uniform_bucket_level_access)