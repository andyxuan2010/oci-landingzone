# Local example values. Environment-specific values live under environments/<env>/.
# For normal work, prefer:
# terraform plan -var-file="environments/dev/terraform.tfvars"

region           = "ca-montreal-1"
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaats4u3agsrtsqq52et7penbl64hzitb45hsholkx73kcblo2ps7gq"
compartment_ocid = "ocid1.compartment.oc1..aaaaaaaaf32ydu3yibdhssqdwjiomnihf64mgs35zyum7r3re5feglq2lv3q"

auth                = "APIKey"
config_file_profile = "DEFAULT"
user_ocid           = "ocid1.user.oc1..aaaaaaaavtdkqhu336wem37crkrfgvnnlvtpq75ow5r32raxkdie4pghchja"
fingerprint         = "f4:08:23:1f:68:a9:71:45:74:3c:d3:96:be:6c:58:83"
private_key_path    = "C:/Users/administrator/.oci/oci_api_key.pem"

workload    = "platform"
environment = "dev"

features = {
  enable_compartment      = false
  enable_service_gateway  = false
  enable_drg              = false
  enable_dns_zones        = false
  enable_iam              = false
  enable_compute          = false
  enable_block_volume     = false
  enable_file_storage     = false
  enable_load_balancer    = false
  enable_object_storage   = true
  enable_vault            = false
  enable_kms_key          = false
  enable_internet_gateway = false
  enable_nat_gateway      = false
}

freeform_tags = {
  cost_center = "ccoe"
  owner       = "cloud-platform"
}

vcn_cidr_blocks = ["10.20.0.0/16"]

subnets = {
  app = {
    cidr_block                 = "10.20.1.0/24"
    dns_label                  = "app"
    prohibit_public_ip_on_vnic = true
  }
  private = {
    cidr_block                 = "10.20.2.0/24"
    dns_label                  = "priv"
    prohibit_public_ip_on_vnic = true
  }
}
