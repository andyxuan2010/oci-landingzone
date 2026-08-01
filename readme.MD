# OCI Landing Zone

Terraform landing zone repository for provisioning a shared Oracle Cloud Infrastructure foundation and a small set of optional platform workloads.

This repo is a consumer of the shared Terraform modules hosted in the public [`andyxuan2010/oci-template`](https://github.com/andyxuan2010/oci-template/tree/main/modules) repository. Its primary job is to compose those modules into a working OCI landing zone, validate the root deployment path, and document the operating patterns used by this stack.

## What This Repo Does

- Provisions a root OCI landing zone composition from `main.tf` and `variables.tf`
- Stores environment-specific backend and variable files under `environments/<env>/`
- Consumes shared Terraform modules from the public `oci-template` repository
- Manages a baseline for compartment, networking, service gateway, NSG, subnets, Object Storage, and optional Vault/KMS
- Wires optional OCI modules for DRG, IAM, DNS, compute, block volume, file storage, and load balancer
- Provides documentation under `docs/` for current resources and root module dependencies

## Current Provisioned Scope

The default checked-in environment configuration is wired to provision:

- A workload compartment, unless an existing compartment OCID is supplied
- A VCN with private subnets
- A route table with NAT gateway private egress by default
- A service gateway for private access to Oracle services
- A workload Network Security Group
- An Object Storage bucket
- Optional Vault and KMS key in dev/prod examples

For the architecture and detailed inventory, see [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md), [docs/CURRENT_LANDINGZONE_RESOURCES.md](./docs/CURRENT_LANDINGZONE_RESOURCES.md), and [docs/ROOT_LEVEL_MODULES_GUIDE.md](./docs/ROOT_LEVEL_MODULES_GUIDE.md).

## Module Sources

All root module blocks use Terraform Git sources:

```hcl
source = "git::https://github.com/andyxuan2010/oci-template.git//modules/<module-name>?ref=main"
```

The previous sibling-repo source path is left commented above each module source in `main.tf` for local development reference.

## Repo Layout

- [`main.tf`](./main.tf): root OCI landing zone composition
- [`variables.tf`](./variables.tf): root inputs and validation
- [`locals.tf`](./locals.tf): naming, tags, feature flags, and shared derived values
- [`outputs.tf`](./outputs.tf): root outputs
- [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md): OCI landing zone architecture design
- [`docs/PIPELINE.md`](./docs/PIPELINE.md): GitHub Actions triggers, configuration, job behavior, and validation record
- [`environments/dev/terraform.tfvars`](./environments/dev/terraform.tfvars): dev environment values and enabled features
- [`environments/dev/backend.hcl`](./environments/dev/backend.hcl): dev remote backend config template
- [`environments/sandbox/terraform.tfvars`](./environments/sandbox/terraform.tfvars): sandbox environment values and enabled features
- [`environments/prod/terraform.tfvars`](./environments/prod/terraform.tfvars): production placeholder values
- [`docs/`](./docs/README.md): documentation map for this repo
- [`.github/workflows/terraform.yml`](./.github/workflows/terraform.yml): GitHub Actions validation, plan, apply, and stage-publish workflow

## Environment Setup

Install:

1. Terraform CLI 1.5 or newer.
2. OCI CLI.
3. An OCI tenancy, region, user, compartment strategy, and IAM policy that allows Terraform to manage the target resources.

For local API key auth:

1. Generate an OCI API signing key.
2. Upload the public key to your OCI user.
3. Configure `~/.oci/config` or set the values in your tfvars file:
   - `tenancy_ocid`
   - `user_ocid`
   - `fingerprint`
   - `private_key_path`
   - `region`

For short-lived local auth:

```powershell
oci session authenticate --profile tf --region us-ashburn-1
```

Then use:

```hcl
auth                = "SecurityToken"
config_file_profile = "tf"
```

## How To Work In This Repo

### 1. Update environment inputs

Most day-to-day changes happen in:

- [`environments/dev/terraform.tfvars`](./environments/dev/terraform.tfvars)
- [`variables.tf`](./variables.tf)
- [`main.tf`](./main.tf)

Use outputs from one module wiring block to feed the next whenever possible instead of hard-coding OCI resource OCIDs into environment files.

### 2. Validate locally

Common local checks:

```powershell
terraform fmt -recursive
terraform init -backend=false
terraform validate
terraform plan -var-file="environments/dev/terraform.tfvars"
```

If you are changing a shared module in the sibling `oci-template` repo, do module-level validation in that module repo as well.

The GitHub Actions workflow performs the same formatting and validation checks for pushes and pull requests targeting `main`, `dev`, and `sbx`. See [docs/PIPELINE.md](./docs/PIPELINE.md) for its branch mapping, required secrets and variables, plan/apply safeguards, and latest validation record.

### 3. Initialize remote state

The root `backend.tf` stores remote state in OCI Object Storage. Initialize it with an environment backend file and OCI customer secret keys:

```powershell
terraform init `
  -reconfigure `
  -backend-config="environments/dev/backend.hcl" `
  -backend-config="access_key=<oci-customer-secret-key-access-key>" `
  -backend-config="secret_key=<oci-customer-secret-key-secret>"
```

## OCI Notes

- Compartments are the primary workload isolation boundary.
- VCNs provide the network address boundary.
- NSGs attach to VNICs and load balancers, not directly to subnets.
- Object Storage buckets are private by default in the shared module.
- Compute is disabled by default until image, SSH key, and bootstrap choices are explicit.
- Optional modules are feature-flagged so environments can grow without changing root wiring.
