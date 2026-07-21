output "compartment_id" {
  description = "Workload compartment OCID."
  value       = local.compartment_id
}

output "vcn_id" {
  description = "VCN OCID."
  value       = module.vcn.id
}

output "vcn_cidr_blocks" {
  description = "VCN CIDR blocks."
  value       = module.vcn.cidr_blocks
}

output "route_table_id" {
  description = "Route table OCID."
  value       = module.route_table.id
}

output "internet_gateway_id" {
  description = "Internet gateway OCID when enabled."
  value       = module.route_table.internet_gateway_id
}

output "nat_gateway_id" {
  description = "NAT gateway OCID when enabled."
  value       = module.route_table.nat_gateway_id
}

output "service_gateway_id" {
  description = "Service gateway OCID when enabled."
  value       = try(module.service_gateway[0].id, null)
}

output "network_security_group_id" {
  description = "Default workload NSG OCID."
  value       = module.network_security_group.id
}

output "subnet_ids" {
  description = "Subnet OCIDs keyed by logical subnet name."
  value       = module.subnet.ids
}

output "drg_id" {
  description = "DRG OCID when enabled."
  value       = try(module.drg[0].id, null)
}

output "drg_vcn_attachment_ids" {
  description = "DRG VCN attachment OCIDs keyed by logical attachment name when enabled."
  value       = try(module.drg[0].vcn_attachment_ids, {})
}

output "object_storage_bucket_name" {
  description = "Object Storage bucket name when enabled."
  value       = try(module.object_storage[0].name, null)
}

output "vault_id" {
  description = "Vault OCID when enabled."
  value       = try(module.vault[0].id, null)
}

output "kms_key_id" {
  description = "KMS key OCID when enabled."
  value       = try(module.kms_key[0].id, null)
}

output "dns_zone_ids" {
  description = "DNS zone OCIDs keyed by logical name when enabled."
  value       = { for key, zone in module.dns_zone : key => zone.id }
}

output "dynamic_group_ids" {
  description = "Dynamic group OCIDs keyed by logical name when enabled."
  value       = { for key, group in module.dynamic_group : key => group.id }
}

output "iam_policy_ids" {
  description = "IAM policy OCIDs keyed by logical name when enabled."
  value       = { for key, policy in module.iam_policy : key => policy.id }
}

output "compute_instance_id" {
  description = "Compute instance OCID when enabled."
  value       = try(module.compute_instance[0].id, null)
}

output "compute_private_ip" {
  description = "Compute private IP when enabled."
  value       = try(module.compute_instance[0].private_ip, null)
}

output "block_volume_id" {
  description = "Block volume OCID when enabled."
  value       = try(module.block_volume[0].id, null)
}

output "file_storage_mount_target_id" {
  description = "File Storage mount target OCID when enabled."
  value       = try(module.file_storage[0].mount_target_id, null)
}

output "load_balancer_id" {
  description = "Load balancer OCID when enabled."
  value       = try(module.load_balancer[0].id, null)
}
