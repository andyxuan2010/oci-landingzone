# OCI Landing Zone Resource Inventory

This file lists the OCI landing zone resources wired in the root Terraform module.

Scope:

- Root wiring in `main.tf`
- Current checked-in environment inputs in `environments/sandbox/terraform.tfvars`, `environments/dev/terraform.tfvars`, and `environments/prod/terraform.tfvars`
- Resources currently active, plus resources that are already wired and can be provisioned by changing feature flags

## Current Feature State

The environment files use the same high-level `features` map pattern as the sibling landing zone repo.

| Feature | Sandbox | Dev | Prod placeholder | Effect |
| --- | --- | --- | --- | --- |
| `enable_compartment` | `true` | `true` | `true` | Creates a workload compartment unless replaced with an existing compartment. |
| `enable_service_gateway` | `true` | `true` | `true` | Creates an OCI service gateway. |
| `enable_object_storage` | `true` | `true` | `true` | Creates a private Object Storage bucket. |
| `enable_vault` | `false` | `true` | `true` | Creates an OCI Vault. |
| `enable_kms_key` | `false` | `true` | `true` | Creates a KMS key in the root-managed Vault. |
| `enable_nat_gateway` | `true` | `true` | `true` | Creates NAT gateway egress through the route table. |
| `enable_internet_gateway` | `false` | `false` | `false` | Internet gateway wiring is available but off. |
| `enable_drg` | `false` | `false` | `false` | DRG wiring is available but off. |
| `enable_dns_zones` | `false` | `false` | `false` | DNS zone wiring is available but off. |
| `enable_iam` | `false` | `false` | `false` | IAM policy and dynamic group wiring is available but off. |
| `enable_compute` | `false` | `false` | `false` | Compute wiring is available but off. |
| `enable_block_volume` | `false` | `false` | `false` | Block volume wiring is available but off. |
| `enable_file_storage` | `false` | `false` | `false` | File Storage wiring is available but off. |
| `enable_load_balancer` | `false` | `false` | `false` | Load balancer wiring is available but off. |

## Currently Provisioned By The Checked-In Feature Maps

These resources are active without changing the top-level feature map in sandbox/dev.

### Governance

| Terraform address | OCI resource or configuration |
| --- | --- |
| `module.compartment` | Workload compartment under the tenancy when enabled. |

### Network

| Terraform address | OCI resource or configuration |
| --- | --- |
| `module.vcn` | Landing zone VCN. |
| `module.route_table` | Route table plus NAT gateway by default. |
| `module.service_gateway` | Private access to Oracle services through the VCN. |
| `module.network_security_group` | Default workload NSG. |
| `module.subnet` | Subnets defined in each environment file. |

The checked-in dev and sandbox files define:

- `app`
- `private`

### Data Protection And Storage

| Terraform address | OCI resource or configuration |
| --- | --- |
| `module.object_storage` | Private Object Storage bucket. |
| `module.vault` | OCI Vault when enabled. |
| `module.kms_key` | KMS key when Vault and KMS are enabled. |

## Wired But Not Currently Provisioned

These are already connected in `main.tf` and can be provisioned by changing flags or configured maps.

| Resource area | Terraform address | How to turn on |
| --- | --- | --- |
| DRG | `module.drg` | Set `features.enable_drg = true`; keep `drg_attach_vcn = true` to attach the landing zone VCN. |
| DNS zones | `module.dns_zone` | Set `features.enable_dns_zones = true` and populate `dns_zones`. |
| IAM dynamic groups | `module.dynamic_group` | Set `features.enable_iam = true` and populate `dynamic_groups`. |
| IAM policies | `module.iam_policy` | Set `features.enable_iam = true` and populate `iam_policies`. |
| Compute | `module.compute_instance` | Set `features.enable_compute = true`, then provide `compute_image_ocid` and `ssh_public_key`. |
| Block volume | `module.block_volume` | Set `features.enable_block_volume = true`; optionally attach to compute. |
| File Storage | `module.file_storage` | Set `features.enable_file_storage = true`. |
| Load balancer | `module.load_balancer` | Set `features.enable_load_balancer = true` and provide backend/listener maps as needed. |

## Not In Scope

This repository is scoped to OCI-native landing zone resources available in the public OCI module set.
