# bucket    = "<bucket-name>"
# namespace = "<object-storage-namespace>"
# region    = "us-ashburn-1"
# key       = "oci-landingzone/prod/terraform.tfstate"
# endpoints = {
#   s3 = "https://<object-storage-namespace>.compat.objectstorage.us-ashburn-1.oraclecloud.com"
# }

terraform {
  backend "oci" {
    bucket    = "tfstate-oci-template-dev"
    namespace = "axd3ykz55kyd"
    region    = "ca-montreal-1"
    key       = "oci-landingzone/dev/terraform.tfstate"
  }
}