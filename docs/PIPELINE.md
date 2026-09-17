# Terraform Pipeline

The [`Terraform OCI`](../.github/workflows/terraform.yml) GitHub Actions workflow validates the landing zone, optionally creates an OCI plan and apply, and can publish a clean snapshot to a separate demonstration repository.

## Triggers and environments

The workflow runs for pushes and pull requests targeting `main`, `dev`, or `sbx`, and it can also be started manually with `workflow_dispatch`.

| Branch | GitHub environment | Terraform variable file |
| --- | --- | --- |
| `main` | `prod` | `environments/prod/terraform.tfvars` |
| `dev` | `dev` | `environments/dev/terraform.tfvars` |
| `sbx` | `sbx` | `environments/sandbox/terraform.tfvars` |

## Job behavior

1. **Check Required Secrets and Variables** reports whether OCI credentials, remote-state inputs, apply authorization, and stage-publishing inputs are available.
2. **Validate OCI Terraform** runs `terraform init -backend=false`, `terraform fmt -check -recursive`, `terraform validate`, and `./test.ps1`.
3. **Publish Github Demo Repo** publishes a clean snapshot on non-pull-request runs when `STAGE_REPOSITORY` and `STAGE_REPO_TOKEN` are configured. It skips publishing back into the same stage repository to prevent loops.
4. **Plan OCI Terraform** runs after successful validation on non-pull-request events when all OCI credentials are present. It uploads the generated plan as a workflow artifact.
5. **Apply OCI Terraform** runs only after a successful plan and explicit apply authorization. Set repository variable `ENABLE_GITHUB_APPLY=true`, or manually dispatch the workflow with `apply=true`.

A skipped plan or apply is expected when OCI credentials or apply authorization are absent. Pull requests perform validation only and do not plan, apply, or publish the stage repository.

## GitHub configuration

Configure these repository or environment values as needed:

- OCI plan/apply: variable `OCI_REGION`; secrets `OCI_TENANCY_OCID`, `OCI_USER_OCID`, `OCI_FINGERPRINT`, and `OCI_PRIVATE_KEY`.
- Remote state: variables `TF_BACKEND_READY=true`, `TF_BACKEND_BUCKET`, `TF_BACKEND_NAMESPACE`, `TF_BACKEND_REGION`, and `TF_BACKEND_KEY`; secrets `OCI_STATE_ACCESS_KEY_ID` and `OCI_STATE_SECRET_ACCESS_KEY`.
- Apply authorization: variable `ENABLE_GITHUB_APPLY=true`, or the manual `apply=true` workflow input.
- Stage publishing: variable `STAGE_REPOSITORY` in `owner/repo` or GitHub URL form, plus secret `STAGE_REPO_TOKEN` with write access to that repository.

Use GitHub environment protection rules on `prod` if production applies require reviewer approval.

## Validation record

The pipeline was validated on July 18, 2026 by push commit `5f1023f`. [GitHub Actions run 29633960462](https://github.com/CCOE-Azure/oci-landingzone/actions/runs/29633960462) completed successfully:

- Required secret and variable checks passed.
- Terraform initialization, formatting, configuration validation, and module tests passed.
- Publishing to the configured demonstration repository passed.
- Plan and apply were skipped because their configured eligibility conditions were not met; no OCI infrastructure was changed.

