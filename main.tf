# -------------------------------------------------------------------
# Governance: Workload Compartment
# -------------------------------------------------------------------

module "compartment" {
  count = local.feature_flags.enable_compartment ? 1 : 0

  # source = "../oci-template/modules/compartment"
  source = "git::https://github.com/andyxuan2010/oci-template.git//modules/compartment?ref=main"

  parent_compartment_id = var.tenancy_ocid
  name                  = local.names.compartment
  description           = "Landing zone compartment for ${var.workload} ${var.environment}"
  freeform_tags         = local.freeform_tags
  defined_tags          = var.defined_tags
}

# -------------------------------------------------------------------
# Network: VCN, Egress, Service Gateway, NSG, Subnets, DRG
# -------------------------------------------------------------------

module "vcn" {
  # source = "../oci-template/modules/vcn"
  source = "git::https://github.com/andyxuan2010/oci-template.git//modules/vcn?ref=main"

  compartment_id = local.compartment_id
  display_name   = local.names.vcn
  cidr_blocks    = var.vcn_cidr_blocks
  dns_label      = replace(substr("${var.workload}${local.environment_code}", 0, 15), "-", "")
  freeform_tags  = local.freeform_tags
  defined_tags   = var.defined_tags
}

module "route_table" {
  # source = "../oci-template/modules/route_table"
  source = "git::https://github.com/andyxuan2010/oci-template.git//modules/route_table?ref=main"

  compartment_id          = local.compartment_id
  vcn_id                  = module.vcn.id
  display_name            = local.names.route_table
  enable_internet_gateway = local.feature_flags.enable_internet_gateway
  enable_nat_gateway      = local.feature_flags.enable_nat_gateway
  route_rules             = local.effective_route_rules
  freeform_tags           = local.freeform_tags
  defined_tags            = var.defined_tags
}

module "service_gateway" {
  count = local.feature_flags.enable_service_gateway ? 1 : 0

  # source = "../oci-template/modules/service_gateway"
  source = "git::https://github.com/andyxuan2010/oci-template.git//modules/service_gateway?ref=main"

  compartment_id = local.compartment_id
  vcn_id         = module.vcn.id
  display_name   = local.names.service_gateway
  services       = local.service_gateway_services
  route_table_id = module.route_table.id
  freeform_tags  = local.freeform_tags
  defined_tags   = var.defined_tags
}

module "network_security_group" {
  # source = "../oci-template/modules/network_security_group"
  source = "git::https://github.com/andyxuan2010/oci-template.git//modules/network_security_group?ref=main"

  compartment_id = local.compartment_id
  vcn_id         = module.vcn.id
  display_name   = local.names.network_security_group
  ingress_rules  = var.nsg_ingress_rules
  egress_rules   = var.nsg_egress_rules
  freeform_tags  = local.freeform_tags
  defined_tags   = var.defined_tags
}

module "subnet" {
  # source = "../oci-template/modules/subnet"
  source = "git::https://github.com/andyxuan2010/oci-template.git//modules/subnet?ref=main"

  compartment_id         = local.compartment_id
  vcn_id                 = module.vcn.id
  default_route_table_id = module.route_table.id
  subnets = {
    for name, subnet in var.subnets : name => merge(subnet, {
      security_list_ids = length(subnet.security_list_ids) > 0 ? subnet.security_list_ids : [module.vcn.default_security_list_id]
    })
  }
  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

module "drg" {
  count = local.feature_flags.enable_drg ? 1 : 0

  # source = "../oci-template/modules/drg"
  source = "git::https://github.com/andyxuan2010/oci-template.git//modules/drg?ref=main"

  compartment_id = local.compartment_id
  display_name   = local.names.drg
  vcn_attachments = var.drg_attach_vcn ? {
    landingzone = {
      vcn_id       = module.vcn.id
      display_name = "${local.names.drg}-to-${local.names.vcn}"
    }
  } : {}
  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# -------------------------------------------------------------------
# Security: Vault, KMS, IAM
# -------------------------------------------------------------------

module "vault" {
  count = local.feature_flags.enable_vault ? 1 : 0

  # source = "../oci-template/modules/vault"
  source = "git::https://github.com/andyxuan2010/oci-template.git//modules/vault?ref=main"

  compartment_id = local.compartment_id
  display_name   = local.names.vault
  freeform_tags  = local.freeform_tags
  defined_tags   = var.defined_tags
}

module "kms_key" {
  count = local.feature_flags.enable_vault && local.feature_flags.enable_kms_key ? 1 : 0

  # source = "../oci-template/modules/kms_key"
  source = "git::https://github.com/andyxuan2010/oci-template.git//modules/kms_key?ref=main"

  compartment_id      = local.compartment_id
  management_endpoint = module.vault[0].management_endpoint
  display_name        = local.names.kms_key
  protection_mode     = var.kms_key_protection_mode
  freeform_tags       = local.freeform_tags
  defined_tags        = var.defined_tags
}

module "dynamic_group" {
  for_each = local.feature_flags.enable_iam ? var.dynamic_groups : {}

  # source = "../oci-template/modules/dynamic_group"
  source = "git::https://github.com/andyxuan2010/oci-template.git//modules/dynamic_group?ref=main"

  compartment_id = var.tenancy_ocid
  name           = each.value.name
  description    = each.value.description
  matching_rule  = each.value.matching_rule
  freeform_tags  = local.freeform_tags
  defined_tags   = var.defined_tags
}

module "iam_policy" {
  for_each = local.feature_flags.enable_iam ? var.iam_policies : {}

  # source = "../oci-template/modules/iam_policy"
  source = "git::https://github.com/andyxuan2010/oci-template.git//modules/iam_policy?ref=main"

  compartment_id = local.compartment_id
  name           = each.value.name
  description    = each.value.description
  statements     = each.value.statements
  version_date   = try(each.value.version_date, null)
  freeform_tags  = local.freeform_tags
  defined_tags   = var.defined_tags
}

# -------------------------------------------------------------------
# Foundation Data Services: Object Storage And DNS
# -------------------------------------------------------------------

module "object_storage" {
  count = local.feature_flags.enable_object_storage ? 1 : 0

  # source = "../oci-template/modules/object_storage"
  source = "git::https://github.com/andyxuan2010/oci-template.git//modules/object_storage?ref=main"

  compartment_id = local.compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = local.names.object_storage_bucket
  freeform_tags  = local.freeform_tags
  defined_tags   = var.defined_tags
}

module "dns_zone" {
  for_each = local.feature_flags.enable_dns_zones ? var.dns_zones : {}

  # source = "../oci-template/modules/dns_zone"
  source = "git::https://github.com/andyxuan2010/oci-template.git//modules/dns_zone?ref=main"

  compartment_id = local.compartment_id
  name           = each.value.name
  zone_type      = try(each.value.zone_type, "PRIMARY")
  scope          = try(each.value.scope, "GLOBAL")
  view_id        = try(each.value.view_id, null)
  freeform_tags  = local.freeform_tags
  defined_tags   = var.defined_tags
}

# -------------------------------------------------------------------
# Optional Workloads: Compute, Block Volume, File Storage, Load Balancer
# -------------------------------------------------------------------

module "compute_instance" {
  count = local.feature_flags.enable_compute ? 1 : 0

  # source = "../oci-template/modules/compute_instance"
  source = "git::https://github.com/andyxuan2010/oci-template.git//modules/compute_instance?ref=main"

  compartment_id      = local.compartment_id
  availability_domain = local.first_ad
  display_name        = local.names.compute_instance
  shape               = var.compute_shape
  ocpus               = var.compute_ocpus
  memory_in_gbs       = var.compute_memory_in_gbs
  image_ocid          = var.compute_image_ocid
  subnet_id           = module.subnet.ids[var.compute_subnet_key]
  nsg_ids             = [module.network_security_group.id]
  assign_public_ip    = var.compute_assign_public_ip
  ssh_public_key      = var.ssh_public_key
  freeform_tags       = local.freeform_tags
  defined_tags        = var.defined_tags
}

module "block_volume" {
  count = local.feature_flags.enable_block_volume ? 1 : 0

  # source = "../oci-template/modules/block_volume"
  source = "git::https://github.com/andyxuan2010/oci-template.git//modules/block_volume?ref=main"

  compartment_id        = local.compartment_id
  availability_domain   = local.first_ad
  display_name          = local.names.block_volume
  size_in_gbs           = var.block_volume_size_in_gbs
  vpus_per_gb           = var.block_volume_vpus_per_gb
  kms_key_id            = local.kms_key_id
  attach_to_instance_id = var.attach_block_volume_to_compute && local.feature_flags.enable_compute ? module.compute_instance[0].id : null
  freeform_tags         = local.freeform_tags
  defined_tags          = var.defined_tags
}

module "file_storage" {
  count = local.feature_flags.enable_file_storage ? 1 : 0

  # source = "../oci-template/modules/file_storage"
  source = "git::https://github.com/andyxuan2010/oci-template.git//modules/file_storage?ref=main"

  compartment_id            = local.compartment_id
  availability_domain       = local.first_ad
  file_system_display_name  = local.names.file_system
  mount_target_display_name = local.names.mount_target
  subnet_id                 = module.subnet.ids[var.file_storage_subnet_key]
  nsg_ids                   = [module.network_security_group.id]
  kms_key_id                = local.kms_key_id
  export_path               = var.file_storage_export_path
  freeform_tags             = local.freeform_tags
  defined_tags              = var.defined_tags
}

module "load_balancer" {
  count = local.feature_flags.enable_load_balancer ? 1 : 0

  # source = "../oci-template/modules/load_balancer"
  source = "git::https://github.com/andyxuan2010/oci-template.git//modules/load_balancer?ref=main"

  compartment_id             = local.compartment_id
  display_name               = local.names.load_balancer
  minimum_bandwidth_in_mbps  = var.load_balancer_minimum_bandwidth_in_mbps
  maximum_bandwidth_in_mbps  = var.load_balancer_maximum_bandwidth_in_mbps
  subnet_ids                 = [for subnet_key in var.load_balancer_subnet_keys : module.subnet.ids[subnet_key]]
  is_private                 = var.load_balancer_is_private
  network_security_group_ids = [module.network_security_group.id]
  backend_sets               = var.load_balancer_backend_sets
  backends                   = var.load_balancer_backends
  listeners                  = var.load_balancer_listeners
  freeform_tags              = local.freeform_tags
  defined_tags               = var.defined_tags
}
