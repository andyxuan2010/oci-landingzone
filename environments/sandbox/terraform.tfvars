# -------------------------------------------------------------------
# Shared Landing Zone Inputs
# -------------------------------------------------------------------

region       = "us-ashburn-1"
tenancy_ocid = "ocid1.tenancy.oc1..replace-me"

auth                = "SecurityToken"
config_file_profile = "tf"

workload    = "platform"
environment = "sandbox"

features = {
  enable_compartment      = true
  enable_service_gateway  = true
  enable_drg              = false
  enable_dns_zones        = false
  enable_iam              = false
  enable_compute          = false
  enable_block_volume     = false
  enable_file_storage     = false
  enable_load_balancer    = false
  enable_object_storage   = true
  enable_vault            = true
  enable_kms_key          = true
  enable_internet_gateway = false
  enable_nat_gateway      = true
}

freeform_tags = {
  cost_center = "ccoe"
  owner       = "cloud-platform"
}

# -------------------------------------------------------------------
# Network Inputs
# -------------------------------------------------------------------

vcn_cidr_blocks = ["10.30.0.0/16"]

subnets = {
  app = {
    cidr_block                 = "10.30.1.0/24"
    dns_label                  = "app"
    prohibit_public_ip_on_vnic = true
  }
  private = {
    cidr_block                 = "10.30.2.0/24"
    dns_label                  = "priv"
    prohibit_public_ip_on_vnic = true
  }
}

nsg_ingress_rules = [
  {
    protocol    = "6"
    source      = "10.30.0.0/16"
    source_type = "CIDR_BLOCK"
    description = "Allow SSH from inside the landing zone VCN"
    tcp_options = {
      min = 22
      max = 22
    }
  }
]
