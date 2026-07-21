variable "region" {
  description = "OCI region identifier, for example us-ashburn-1."
  type        = string
}

variable "tenancy_ocid" {
  description = "Root tenancy OCID."
  type        = string
}

variable "compartment_ocid" {
  description = "Existing workload compartment OCID. Required when create_compartment or features.enable_compartment is false."
  type        = string
  default     = ""
}

variable "auth" {
  description = "OCI provider authentication method: APIKey, SecurityToken, InstancePrincipal, ResourcePrincipal, or OKEWorkloadIdentity."
  type        = string
  default     = "APIKey"
}

variable "config_file_profile" {
  description = "OCI CLI config profile to use."
  type        = string
  default     = "DEFAULT"
}

variable "user_ocid" {
  description = "OCI user OCID for API key authentication."
  type        = string
  default     = null
}

variable "fingerprint" {
  description = "API key fingerprint for API key authentication."
  type        = string
  default     = null
}

variable "private_key_path" {
  description = "Path to the OCI API private key for API key authentication."
  type        = string
  default     = null
}

variable "private_key" {
  description = "PEM-encoded OCI API private key for API key authentication. Takes precedence over private_key_path."
  type        = string
  default     = null
  sensitive   = true
}

variable "workload" {
  description = "Short workload or platform identifier used in generated names."
  type        = string
  default     = "platform"

  validation {
    condition     = length(trimspace(var.workload)) >= 3 && length(trimspace(var.workload)) <= 16
    error_message = "workload must be 3 to 16 characters."
  }
}

variable "environment" {
  description = "Environment name such as dev, sandbox, prod, test, qa, or poc."
  type        = string
  default     = "dev"
}

variable "features" {
  description = "High-level feature switches. Known keys include enable_compartment, enable_service_gateway, enable_drg, enable_dns_zones, enable_iam, enable_compute, enable_block_volume, enable_file_storage, enable_load_balancer, enable_object_storage, enable_vault, enable_kms_key, enable_internet_gateway, and enable_nat_gateway."
  type        = map(bool)
  default     = {}
}

variable "freeform_tags" {
  description = "Common OCI freeform tags merged with root-managed workload, environment, managed_by, and repository tags."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Common OCI defined tags."
  type        = map(string)
  default     = {}
}

variable "create_compartment" {
  description = "Whether to create a child compartment for this landing zone."
  type        = bool
  default     = true
}

variable "compartment_name" {
  description = "Optional compartment name override."
  type        = string
  default     = ""
}

variable "vcn_display_name" {
  description = "Optional VCN display name override."
  type        = string
  default     = ""
}

variable "vcn_cidr_blocks" {
  description = "CIDR blocks for the landing zone VCN."
  type        = list(string)
  default     = ["10.20.0.0/16"]
}

variable "route_table_display_name" {
  description = "Optional route table display name override."
  type        = string
  default     = ""
}

variable "enable_internet_gateway" {
  description = "Create an internet gateway and use it for default egress when NAT is disabled."
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway and use it for default private egress."
  type        = bool
  default     = true
}

variable "additional_route_rules" {
  description = "Additional route rules appended to the root-managed default egress route."
  type = list(object({
    destination      = string
    destination_type = optional(string, "CIDR_BLOCK")
    network_entity   = string
    description      = optional(string)
  }))
  default = []
}

variable "enable_service_gateway" {
  description = "Whether to create an OCI service gateway for private access to Oracle services."
  type        = bool
  default     = true
}

variable "service_gateway_display_name" {
  description = "Optional service gateway display name override."
  type        = string
  default     = ""
}

variable "service_gateway_services" {
  description = "OCI services enabled on the service gateway. Leave empty to use the regional All Services In Oracle Services Network service."
  type = list(object({
    service_id   = optional(string)
    service_name = optional(string)
  }))
  default = []
}

variable "network_security_group_display_name" {
  description = "Optional default workload NSG display name override."
  type        = string
  default     = ""
}

variable "nsg_ingress_rules" {
  description = "Ingress NSG rules for the default workload NSG."
  type = list(object({
    protocol    = string
    source      = string
    source_type = optional(string, "CIDR_BLOCK")
    stateless   = optional(bool, false)
    description = optional(string)
    tcp_options = optional(object({ min = number, max = number }))
    udp_options = optional(object({ min = number, max = number }))
    icmp_options = optional(object({
      type = number
      code = optional(number)
    }))
  }))
  default = []
}

variable "nsg_egress_rules" {
  description = "Egress NSG rules for the default workload NSG."
  type = list(object({
    protocol         = string
    destination      = string
    destination_type = optional(string, "CIDR_BLOCK")
    stateless        = optional(bool, false)
    description      = optional(string)
    tcp_options      = optional(object({ min = number, max = number }))
    udp_options      = optional(object({ min = number, max = number }))
    icmp_options = optional(object({
      type = number
      code = optional(number)
    }))
  }))
  default = [
    {
      protocol         = "all"
      destination      = "0.0.0.0/0"
      destination_type = "CIDR_BLOCK"
      description      = "Allow outbound traffic"
    }
  ]
}

variable "subnets" {
  description = "Subnet definitions keyed by logical subnet name."
  type = map(object({
    cidr_block                 = string
    dns_label                  = optional(string)
    prohibit_public_ip_on_vnic = optional(bool, true)
    security_list_ids          = optional(list(string), [])
    route_table_id             = optional(string)
    nsg_ids                    = optional(list(string), [])
  }))
  default = {
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
}

variable "enable_drg" {
  description = "Whether to create a DRG and optionally attach the landing zone VCN."
  type        = bool
  default     = false
}

variable "drg_display_name" {
  description = "Optional DRG display name override."
  type        = string
  default     = ""
}

variable "drg_attach_vcn" {
  description = "Whether the optional DRG should attach to the landing zone VCN."
  type        = bool
  default     = true
}

variable "create_object_storage_bucket" {
  description = "Whether to create a baseline Object Storage bucket."
  type        = bool
  default     = true
}

variable "object_storage_bucket_name" {
  description = "Optional Object Storage bucket name override."
  type        = string
  default     = ""
}

variable "create_vault" {
  description = "Whether to create an OCI Vault."
  type        = bool
  default     = false
}

variable "vault_display_name" {
  description = "Optional Vault display name override."
  type        = string
  default     = ""
}

variable "create_kms_key" {
  description = "Whether to create a KMS key in the root-managed vault."
  type        = bool
  default     = false
}

variable "kms_key_display_name" {
  description = "Optional KMS key display name override."
  type        = string
  default     = ""
}

variable "kms_key_protection_mode" {
  description = "KMS key protection mode. SOFTWARE avoids HSM key-version charges."
  type        = string
  default     = "SOFTWARE"

  validation {
    condition     = contains(["SOFTWARE", "HSM", "EXTERNAL"], var.kms_key_protection_mode)
    error_message = "kms_key_protection_mode must be SOFTWARE, HSM, or EXTERNAL."
  }
}

variable "enable_dns_zones" {
  description = "Whether to create DNS zones from dns_zones."
  type        = bool
  default     = false
}

variable "dns_zones" {
  description = "DNS zones keyed by logical name."
  type = map(object({
    name      = string
    zone_type = optional(string, "PRIMARY")
    scope     = optional(string, "GLOBAL")
    view_id   = optional(string)
  }))
  default = {}
}

variable "enable_iam" {
  description = "Whether to create dynamic groups and IAM policies from the configured maps."
  type        = bool
  default     = false
}

variable "dynamic_groups" {
  description = "Dynamic groups keyed by logical name."
  type = map(object({
    name          = string
    description   = string
    matching_rule = string
  }))
  default = {}
}

variable "iam_policies" {
  description = "IAM policies keyed by logical name."
  type = map(object({
    name         = string
    description  = string
    statements   = list(string)
    version_date = optional(string)
  }))
  default = {}
}

variable "create_compute_instance" {
  description = "Whether to create a sample Linux compute instance."
  type        = bool
  default     = false
}

variable "compute_display_name" {
  description = "Optional compute instance display name override."
  type        = string
  default     = ""
}

variable "compute_shape" {
  description = "OCI compute shape."
  type        = string
  default     = "VM.Standard.E5.Flex"
}

variable "compute_ocpus" {
  description = "OCPUs for flexible shapes."
  type        = number
  default     = 1
}

variable "compute_memory_in_gbs" {
  description = "Memory in GBs for flexible shapes."
  type        = number
  default     = 8
}

variable "compute_image_ocid" {
  description = "Image OCID for the compute instance. Required when compute is enabled."
  type        = string
  default     = ""
}

variable "compute_subnet_key" {
  description = "Subnet map key where the optional compute instance is placed."
  type        = string
  default     = "app"
}

variable "compute_assign_public_ip" {
  description = "Whether to assign a public IP to the optional compute instance."
  type        = bool
  default     = false
}

variable "ssh_public_key" {
  description = "SSH public key for the optional compute instance."
  type        = string
  default     = ""
}

variable "create_block_volume" {
  description = "Whether to create a block volume."
  type        = bool
  default     = false
}

variable "block_volume_display_name" {
  description = "Optional block volume display name override."
  type        = string
  default     = ""
}

variable "block_volume_size_in_gbs" {
  description = "Block volume size in GB."
  type        = number
  default     = 50
}

variable "block_volume_vpus_per_gb" {
  description = "Block volume performance units per GB."
  type        = number
  default     = 10
}

variable "attach_block_volume_to_compute" {
  description = "Attach the optional block volume to the optional compute instance."
  type        = bool
  default     = false
}

variable "create_file_storage" {
  description = "Whether to create OCI File Storage."
  type        = bool
  default     = false
}

variable "file_system_display_name" {
  description = "Optional file system display name override."
  type        = string
  default     = ""
}

variable "mount_target_display_name" {
  description = "Optional mount target display name override."
  type        = string
  default     = ""
}

variable "file_storage_subnet_key" {
  description = "Subnet map key where the optional file storage mount target is placed."
  type        = string
  default     = "private"
}

variable "file_storage_export_path" {
  description = "NFS export path for optional file storage."
  type        = string
  default     = "/export"
}

variable "create_load_balancer" {
  description = "Whether to create an OCI load balancer."
  type        = bool
  default     = false
}

variable "load_balancer_display_name" {
  description = "Optional load balancer display name override."
  type        = string
  default     = ""
}

variable "load_balancer_subnet_keys" {
  description = "Subnet map keys used by the optional load balancer."
  type        = list(string)
  default     = ["app"]
}

variable "load_balancer_is_private" {
  description = "Whether the optional load balancer is private."
  type        = bool
  default     = true
}

variable "load_balancer_minimum_bandwidth_in_mbps" {
  description = "Minimum bandwidth for flexible load balancer shape."
  type        = number
  default     = 10
}

variable "load_balancer_maximum_bandwidth_in_mbps" {
  description = "Maximum bandwidth for flexible load balancer shape."
  type        = number
  default     = 100
}

variable "load_balancer_backend_sets" {
  description = "Optional load balancer backend sets."
  type = map(object({
    policy = optional(string, "ROUND_ROBIN")
    health_checker = object({
      protocol            = string
      port                = number
      url_path            = optional(string)
      return_code         = optional(number)
      retries             = optional(number)
      timeout_in_millis   = optional(number)
      interval_ms         = optional(number)
      response_body_regex = optional(string)
    })
  }))
  default = {}
}

variable "load_balancer_backends" {
  description = "Optional load balancer backends."
  type = map(object({
    backend_set_name = string
    ip_address       = string
    port             = number
    backup           = optional(bool, false)
    drain            = optional(bool, false)
    offline          = optional(bool, false)
    weight           = optional(number, 1)
  }))
  default = {}
}

variable "load_balancer_listeners" {
  description = "Optional load balancer listeners."
  type = map(object({
    default_backend_set_name = string
    port                     = number
    protocol                 = string
    hostname_names           = optional(list(string), [])
    path_route_set_name      = optional(string)
    rule_set_names           = optional(list(string), [])
    ssl_configuration = optional(object({
      certificate_name        = string
      verify_peer_certificate = optional(bool, false)
    }))
  }))
  default = {}
}
