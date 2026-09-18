locals {
  environment_code_map = {
    dev         = "dev"
    development = "dev"
    sbx         = "sbx"
    sandbox     = "sbx"
    prod        = "prod"
    production  = "prod"
    test        = "test"
    qa          = "qa"
    poc         = "poc"
  }

  region_code_map = {
    us-ashburn-1   = "iad"
    us-phoenix-1   = "phx"
    ca-toronto-1   = "yyz"
    ca-montreal-1  = "yul"
    uk-london-1    = "lhr"
    eu-frankfurt-1 = "fra"
  }

  environment_code = lookup(local.environment_code_map, lower(trimspace(var.environment)), lower(trimspace(var.environment)))
  region_code      = lookup(local.region_code_map, lower(trimspace(var.region)), replace(lower(trimspace(var.region)), "-", ""))
  name_suffix      = lower("${var.workload}-${local.region_code}-${local.environment_code}")

  feature_flags = {
    enable_compartment      = lookup(var.features, "enable_compartment", var.create_compartment)
    enable_service_gateway  = lookup(var.features, "enable_service_gateway", var.enable_service_gateway)
    enable_drg              = lookup(var.features, "enable_drg", var.enable_drg)
    enable_dns_zones        = lookup(var.features, "enable_dns_zones", var.enable_dns_zones)
    enable_iam              = lookup(var.features, "enable_iam", var.enable_iam)
    enable_compute          = lookup(var.features, "enable_compute", var.create_compute_instance)
    enable_block_volume     = lookup(var.features, "enable_block_volume", var.create_block_volume)
    enable_file_storage     = lookup(var.features, "enable_file_storage", var.create_file_storage)
    enable_load_balancer    = lookup(var.features, "enable_load_balancer", var.create_load_balancer)
    enable_object_storage   = lookup(var.features, "enable_object_storage", var.create_object_storage_bucket)
    enable_vault            = lookup(var.features, "enable_vault", var.create_vault)
    enable_kms_key          = lookup(var.features, "enable_kms_key", var.create_kms_key)
    enable_internet_gateway = lookup(var.features, "enable_internet_gateway", var.enable_internet_gateway)
    enable_nat_gateway      = lookup(var.features, "enable_nat_gateway", var.enable_nat_gateway)
  }

  default_names = {
    compartment            = "cmp-${local.name_suffix}"
    vcn                    = "vcn-${local.name_suffix}"
    route_table            = "rt-${local.name_suffix}-egress"
    service_gateway        = "sgw-${local.name_suffix}"
    network_security_group = "nsg-${local.name_suffix}-workload"
    drg                    = "drg-${local.name_suffix}"
    vault                  = "vault-${local.name_suffix}"
    kms_key                = "key-${local.name_suffix}"
    object_storage_bucket  = "bucket-${local.name_suffix}"
    compute_instance       = "vm-${local.name_suffix}-001"
    block_volume           = "bv-${local.name_suffix}-001"
    file_system            = "fs-${local.name_suffix}"
    mount_target           = "mt-${local.name_suffix}"
    load_balancer          = "lb-${local.name_suffix}"
  }

  names = {
    compartment            = trimspace(var.compartment_name) != "" ? trimspace(var.compartment_name) : local.default_names.compartment
    vcn                    = trimspace(var.vcn_display_name) != "" ? trimspace(var.vcn_display_name) : local.default_names.vcn
    route_table            = trimspace(var.route_table_display_name) != "" ? trimspace(var.route_table_display_name) : local.default_names.route_table
    service_gateway        = trimspace(var.service_gateway_display_name) != "" ? trimspace(var.service_gateway_display_name) : local.default_names.service_gateway
    network_security_group = trimspace(var.network_security_group_display_name) != "" ? trimspace(var.network_security_group_display_name) : local.default_names.network_security_group
    drg                    = trimspace(var.drg_display_name) != "" ? trimspace(var.drg_display_name) : local.default_names.drg
    vault                  = trimspace(var.vault_display_name) != "" ? trimspace(var.vault_display_name) : local.default_names.vault
    kms_key                = trimspace(var.kms_key_display_name) != "" ? trimspace(var.kms_key_display_name) : local.default_names.kms_key
    object_storage_bucket  = trimspace(var.object_storage_bucket_name) != "" ? trimspace(var.object_storage_bucket_name) : local.default_names.object_storage_bucket
    compute_instance       = trimspace(var.compute_display_name) != "" ? trimspace(var.compute_display_name) : local.default_names.compute_instance
    block_volume           = trimspace(var.block_volume_display_name) != "" ? trimspace(var.block_volume_display_name) : local.default_names.block_volume
    file_system            = trimspace(var.file_system_display_name) != "" ? trimspace(var.file_system_display_name) : local.default_names.file_system
    mount_target           = trimspace(var.mount_target_display_name) != "" ? trimspace(var.mount_target_display_name) : local.default_names.mount_target
    load_balancer          = trimspace(var.load_balancer_display_name) != "" ? trimspace(var.load_balancer_display_name) : local.default_names.load_balancer
  }

  freeform_tags = merge(
    var.freeform_tags,
    {
      workload    = var.workload
      environment = local.environment_code
      managed_by  = "terraform"
      repository  = "oci-landingzone"
    }
  )

  compartment_id = local.feature_flags.enable_compartment ? module.compartment[0].id : var.compartment_ocid
  first_ad       = data.oci_identity_availability_domains.this.availability_domains[0].name

  default_route_rules = local.feature_flags.enable_nat_gateway ? [
    {
      destination      = "0.0.0.0/0"
      destination_type = "CIDR_BLOCK"
      network_entity   = "nat_gateway"
      description      = "Default private egress through NAT gateway"
    }
    ] : local.feature_flags.enable_internet_gateway ? [
    {
      destination      = "0.0.0.0/0"
      destination_type = "CIDR_BLOCK"
      network_entity   = "internet_gateway"
      description      = "Default public egress through internet gateway"
    }
  ] : []

  effective_route_rules = concat(local.default_route_rules, var.additional_route_rules)
  kms_key_id            = local.feature_flags.enable_vault && local.feature_flags.enable_kms_key ? module.kms_key[0].id : null
  service_gateway_services = length(var.service_gateway_services) > 0 ? var.service_gateway_services : [
    {
      service_id = data.oci_core_services.oracle_services.services[0].id
    }
  ]
}
