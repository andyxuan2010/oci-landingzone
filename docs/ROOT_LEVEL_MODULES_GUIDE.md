# Root-Level Module Guide

This document describes the root-level module blocks in `main.tf`, the matching inputs in `variables.tf`, and the recommended dependency order when enabling modules in the OCI landing zone.

## Current Root State

- The root module is organized by landing-zone domains: governance, network, security, foundation data services, and optional workloads.
- Shared module sources point to the public `andyxuan2010/oci-template` GitHub repository.
- Environment-specific values live under `environments/<env>/`.
- The `features` map is the preferred high-level switchboard. If a key exists in `features`, it wins over the older individual boolean variable for that capability.

## Root-Level Module Order

The root file order follows dependency order:

1. `compartment`
2. `vcn`
3. `route_table`
4. `service_gateway`
5. `network_security_group`
6. `subnet`
7. `drg`
8. `vault`
9. `kms_key`
10. `dynamic_group`
11. `iam_policy`
12. `object_storage`
13. `dns_zone`
14. `compute_instance`
15. `block_volume`
16. `file_storage`
17. `load_balancer`

## Root-Level Dependency Matrix

| Root module block | Primary use case | Required dependencies | Common optional dependencies |
| --- | --- | --- | --- |
| `compartment` | Workload isolation boundary | Tenancy OCID | Defined/freeform tags |
| `vcn` | Network boundary | Compartment | Naming and DNS label inputs |
| `route_table` | Egress routing plus NAT/Internet Gateway | VCN | Additional route rules |
| `service_gateway` | Private Oracle services access | VCN, route table | Service list overrides |
| `network_security_group` | Workload traffic control | VCN | Environment-specific ingress rules |
| `subnet` | Landing zone subnet layout | VCN, route table, NSG | Per-subnet route table or NSG overrides |
| `drg` | Hybrid connectivity foundation | VCN | VCN attachment |
| `vault` | Key management boundary | Compartment | KMS keys |
| `kms_key` | Customer-managed encryption key | Vault | Block/File Storage encryption |
| `dynamic_group` | Instance/resource-principal identity grouping | Tenancy | IAM policies |
| `iam_policy` | OCI permissions | Compartment | Dynamic groups |
| `object_storage` | Baseline bucket | Compartment, namespace data source | KMS support if added to module later |
| `dns_zone` | Public or private DNS zones | Compartment | Private view ID |
| `compute_instance` | Optional Linux VM | Subnet, NSG, image OCID, SSH key | Block volume attachment |
| `block_volume` | Optional block storage | Availability domain | KMS key, compute attachment |
| `file_storage` | Optional NFS file system | Availability domain, subnet, NSG | KMS key |
| `load_balancer` | Optional private/public load balancer | Subnets, NSG | Backend sets, backends, listeners |

## Recommended Enablement Order

Use this order when expanding a new environment:

1. Compartment or existing compartment selection.
2. VCN, route table, service gateway, NSG, and subnets.
3. Object Storage bucket.
4. Vault and KMS key.
5. IAM dynamic groups and policies.
6. DRG connectivity.
7. Optional compute, block volume, file storage, and load balancer workloads.

## Module Gaps

No new module was created in the sibling `oci-template` repo during this restructuring because the requested OCI landing-zone baseline can be composed from the OCI modules already present there.
