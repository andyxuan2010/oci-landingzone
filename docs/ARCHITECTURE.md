# OCI Landing Zone Architecture

This document describes the target architecture implemented by this repository. The design is intentionally OCI-native and maps directly to the root Terraform composition in `main.tf`.

## Architecture Goals

- Provide a repeatable OCI landing zone baseline for sandbox, development, and production environments.
- Keep network, security, storage, and workload entry points modular and feature-flagged.
- Use a workload compartment as the default isolation boundary.
- Keep workloads private by default, with controlled egress through NAT gateway and private access to Oracle services through service gateway.
- Store Terraform state in OCI Object Storage when remote state is enabled.
- Consume reusable modules from the public `oci-template` module repository.

## Logical Design

```text
OCI Tenancy
|
+-- Workload Compartment
    |
    +-- VCN
    |   |
    |   +-- Route Table
    |   |   |
    |   |   +-- NAT Gateway, when enabled
    |   |   +-- Internet Gateway, when enabled
    |   |
    |   +-- Service Gateway
    |   |
    |   +-- Network Security Group
    |   |
    |   +-- Subnet: app
    |   |
    |   +-- Subnet: private
    |   |
    |   +-- DRG attachment, when enabled
    |
    +-- Object Storage Bucket
    |
    +-- Vault and KMS Key, when enabled
    |
    +-- DNS Zones, when enabled
    |
    +-- IAM Policies
    |
    +-- Optional Workloads
        |
        +-- Compute Instance
        +-- Block Volume
        +-- File Storage
        +-- Load Balancer
```

## Core Resource Domains

### Governance

The landing zone can create a child compartment under the tenancy or deploy into an existing compartment. The compartment is the main boundary for workload resources, IAM policies, and environment isolation.

Default behavior:

- `features.enable_compartment = true`
- Compartment name is generated from workload, region, and environment.
- Existing compartments can be used by setting `features.enable_compartment = false` and providing `compartment_ocid`.

### Network

The VCN is the central network boundary for the environment. The checked-in environment files define two private-first subnet tiers:

- `app`: primary workload subnet.
- `private`: internal services subnet.

The route table creates private egress through a NAT gateway by default. Internet gateway support is wired but disabled by default.

Default behavior:

- NAT gateway enabled.
- Internet gateway disabled.
- Service gateway enabled.
- Subnets prohibit public IP assignment by default.
- NSG egress allows outbound traffic.
- NSG ingress is environment-specific and scoped to the VCN CIDR in checked-in examples.

### Private Oracle Services Access

The service gateway provides private access from the VCN to Oracle services. The root module discovers the regional Oracle Services Network service and uses that service when no explicit `service_gateway_services` override is provided.

### Security And Key Management

The baseline always creates a workload NSG. Vault and KMS are feature-flagged so lower environments can keep cost and blast radius small while production can enable customer-managed encryption patterns.

Security controls in the current design:

- Compartment isolation.
- Root-managed freeform and defined tags.
- NSG-based workload traffic controls.
- Private subnet defaults.
- Optional Vault and KMS key.
- Optional IAM dynamic groups and policies.

### Storage

Object Storage is part of the baseline and is enabled in all checked-in environment examples. It provides a private bucket for landing-zone artifacts, bootstrap files, or workload storage.

Remote Terraform state is also designed for OCI Object Storage. Backend configuration is kept under `environments/<env>/backend.hcl`, with customer secret keys passed at initialization time.

### Optional Workload Layer

The root module wires optional workload resources without enabling them by default:

- Compute instance in a selected subnet.
- Block volume with optional compute attachment.
- File Storage mount target in a selected subnet.
- Load balancer with configurable backend sets, backends, and listeners.
- DNS zones.
- DRG for hybrid connectivity.
- Dynamic groups and IAM policies.

These are activated with the `features` map and the matching input maps.

## Environment Model

Environment configuration is separated from root Terraform code:

| Environment | File | Purpose |
| --- | --- | --- |
| Sandbox | `environments/sandbox/terraform.tfvars` | Low-risk test environment. |
| Dev | `environments/dev/terraform.tfvars` | Development landing zone with Vault and KMS enabled. |
| Prod | `environments/prod/terraform.tfvars` | Production placeholder requiring final values before apply. |

Each environment also has a matching `backend.hcl` template for remote state in OCI Object Storage.

## Deployment Flow

```text
Developer or CI
|
+-- terraform fmt
|
+-- terraform init
|   |
|   +-- backend=false for local validation
|   +-- OCI Object Storage backend for environment deployments
|
+-- terraform validate
|
+-- terraform plan -var-file=environments/<env>/terraform.tfvars
|
+-- terraform apply, when explicitly enabled
```

The GitHub Actions workflow uses branch-to-environment mapping:

| Branch | Environment file |
| --- | --- |
| `sbx` | `environments/sandbox/terraform.tfvars` |
| `dev` | `environments/dev/terraform.tfvars` |
| `main` | `environments/prod/terraform.tfvars` |

## Module Source Strategy

Root modules consume the public OCI module repository:

```hcl
source = "git::https://github.com/andyxuan2010/oci-template.git//modules/<module-name>?ref=main"
```

The root repo owns composition, environment values, deployment flow, and documentation. The module repo owns reusable OCI resource implementations.

## Security Defaults

- Public IP assignment is disabled on checked-in subnets.
- Compute is disabled until image OCID and SSH key inputs are explicit.
- Internet gateway is disabled by default.
- NAT gateway provides controlled private egress.
- Service gateway keeps Oracle service traffic on the OCI backbone.
- Remote state credentials are passed through backend configuration and are not stored in environment files.
- Production tfvars remain placeholders until environment-specific values are reviewed.

## Expansion Patterns

Use this order when expanding the design:

1. Add or adjust subnets in the environment tfvars file.
2. Tighten NSG ingress and egress rules for the workload.
3. Enable Vault and KMS for encryption requirements.
4. Enable IAM dynamic groups and policies for resource-principal access.
5. Enable DRG when private connectivity is ready.
6. Enable workload modules such as compute, file storage, block volume, or load balancer.

## Operational Boundaries

This repository should stay focused on OCI landing-zone composition. New reusable resource logic belongs in the sibling `oci-template` module repository, then this repo can consume it through the public module source pattern.
