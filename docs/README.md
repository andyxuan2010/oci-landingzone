# Docs Map Of Content

This page is the map of content for everything under `docs/`. Use it as the index before editing Terraform, deployment behavior, or operating patterns.

## Start Here

- [../README.md](../README.md): primary repo guide and best starting point for most contributors.
- [ARCHITECTURE.md](./ARCHITECTURE.md): OCI landing zone architecture design and deployment flow.
- [CURRENT_LANDINGZONE_RESOURCES.md](./CURRENT_LANDINGZONE_RESOURCES.md): resource inventory for what this repo currently provisions.
- [ROOT_LEVEL_MODULES_GUIDE.md](./ROOT_LEVEL_MODULES_GUIDE.md): root module wiring, dependency order, and feature flags.
- [PIPELINE.md](./PIPELINE.md): GitHub Actions triggers, environment mapping, configuration, safeguards, and validation record.
- [OCI_CLI_AUTHENTICATION.md](./OCI_CLI_AUTHENTICATION.md): Windows PowerShell environment variables, OCI CLI profiles, API-key configuration, verification, and troubleshooting.

## Which Doc Should I Read?

- If you want the target landing zone design, start with [ARCHITECTURE.md](./ARCHITECTURE.md).
- If you want a fast answer to what this repo provisions today, start with [CURRENT_LANDINGZONE_RESOURCES.md](./CURRENT_LANDINGZONE_RESOURCES.md).
- If you are changing root Terraform wiring, start with [ROOT_LEVEL_MODULES_GUIDE.md](./ROOT_LEVEL_MODULES_GUIDE.md).
- If you are changing environment inputs, start with the matching `environments/<env>/terraform.tfvars` file and then check [../README.md](../README.md).
- If you are changing CI/CD behavior or repository configuration, start with [PIPELINE.md](./PIPELINE.md).
- If you need to configure or troubleshoot local OCI CLI authentication, start with [OCI_CLI_AUTHENTICATION.md](./OCI_CLI_AUTHENTICATION.md).
