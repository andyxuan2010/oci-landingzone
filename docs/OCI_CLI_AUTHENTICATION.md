# OCI CLI Authentication and Configuration

This guide configures API-key authentication for the OCI CLI on Windows with
PowerShell. It uses environment variables as inputs and writes the standard OCI
CLI config file.

## Prerequisites

- Install the [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm).
- Create or obtain an OCI API signing key and upload its public key to the OCI
  user account.
- Obtain the tenancy OCID, user OCID, API-key fingerprint, private-key path, and
  OCI region.

Verify the CLI installation:

```powershell
oci --version
```

## Set PowerShell Environment Variables

Set variables for the current PowerShell session:

```powershell
$env:OCI_TENANCY_OCID = "ocid1.tenancy.oc1..<value>"
$env:OCI_USER_OCID = "ocid1.user.oc1..<value>"
$env:OCI_FINGERPRINT = "aa:bb:cc:dd:ee:ff:<value>"
$env:OCI_PRIVATE_KEY_PATH = "C:\Users\administrator\.oci\oci_api_key.pem"
$env:OCI_REGION = "ca-toronto-1"
```

Confirm that the private key exists:

```powershell
Test-Path -LiteralPath $env:OCI_PRIVATE_KEY_PATH
```

The result must be `True`.

To persist the values for future shells, set user-level environment variables:

```powershell
[Environment]::SetEnvironmentVariable("OCI_TENANCY_OCID", $env:OCI_TENANCY_OCID, "User")
[Environment]::SetEnvironmentVariable("OCI_USER_OCID", $env:OCI_USER_OCID, "User")
[Environment]::SetEnvironmentVariable("OCI_FINGERPRINT", $env:OCI_FINGERPRINT, "User")
[Environment]::SetEnvironmentVariable("OCI_PRIVATE_KEY_PATH", $env:OCI_PRIVATE_KEY_PATH, "User")
[Environment]::SetEnvironmentVariable("OCI_REGION", $env:OCI_REGION, "User")
```

Open a new PowerShell session after persisting them. Do not store the private
key contents in an environment variable.

## Create the OCI CLI Config

OCI CLI API-key authentication uses a config file. Its default location on
Windows is:

```text
C:\Users\<username>\.oci\config
```

Create the directory and config from the current environment variables:

```powershell
$ociDirectory = Join-Path $HOME ".oci"
$ociConfig = Join-Path $ociDirectory "config"

New-Item -ItemType Directory -Path $ociDirectory -Force | Out-Null

@"
[DEFAULT]
tenancy=$($env:OCI_TENANCY_OCID)
user=$($env:OCI_USER_OCID)
fingerprint=$($env:OCI_FINGERPRINT)
key_file=$($env:OCI_PRIVATE_KEY_PATH)
region=$($env:OCI_REGION)
"@ | Set-Content -LiteralPath $ociConfig -Encoding ascii
```

PowerShell expands the variables before writing the file. The resulting config
must contain actual values:

```ini
[DEFAULT]
tenancy=ocid1.tenancy.oc1..<value>
user=ocid1.user.oc1..<value>
fingerprint=aa:bb:cc:dd:ee:ff:<value>
key_file=C:\Users\administrator\.oci\oci_api_key.pem
region=ca-toronto-1
```

The OCI config format does **not** expand PowerShell expressions. For example,
the following is invalid and causes a `FileNotFoundError`:

```ini
key_file=$env:OCI_PRIVATE_KEY_PATH
```

## Use a Non-default Config or Profile

To use a config file in another location for the current session:

```powershell
$env:OCI_CLI_CONFIG_FILE = "C:\secure\oci\config"
```

Alternatively, specify it for one command:

```powershell
oci iam region list --config-file "C:\secure\oci\config"
```

A config file can contain multiple profiles:

```ini
[DEFAULT]
tenancy=ocid1.tenancy.oc1..<value>
user=ocid1.user.oc1..<value>
fingerprint=aa:bb:cc:<value>
key_file=C:\Users\administrator\.oci\default_key.pem
region=ca-toronto-1

[DEV]
tenancy=ocid1.tenancy.oc1..<value>
user=ocid1.user.oc1..<value>
fingerprint=11:22:33:<value>
key_file=C:\Users\administrator\.oci\dev_key.pem
region=ca-montreal-1
```

Select a named profile with:

```powershell
oci iam region list --profile DEV
```

## Verify Authentication

The CLI reads the config file on every invocation, so it does not need to be
manually loaded or sourced. Test authentication with:

```powershell
oci iam region list
```

Test access to the configured tenancy:

```powershell
oci iam compartment list `
  --compartment-id $env:OCI_TENANCY_OCID `
  --compartment-id-in-subtree true `
  --access-level ACCESSIBLE `
  --all
```

Use debug output when diagnosing configuration problems:

```powershell
oci iam region list --debug
```

Debug output can contain account and request metadata. Review it before sharing
it outside the organization.

## Troubleshooting

### Private-key file not found

Example error:

```text
FileNotFoundError: No such file or directory: '$env:OCI_PRIVATE_KEY_PATH'
```

The config contains an unexpanded variable. Replace `key_file` with the actual
filesystem path and verify it:

```powershell
Select-String -Path "$HOME\.oci\config" -Pattern '^key_file'
Test-Path -LiteralPath $env:OCI_PRIVATE_KEY_PATH
```

### Config file not found

Check the default file and any override:

```powershell
Test-Path -LiteralPath "$HOME\.oci\config"
$env:OCI_CLI_CONFIG_FILE
```

Remove an incorrect session override to return to the default path:

```powershell
Remove-Item Env:OCI_CLI_CONFIG_FILE -ErrorAction SilentlyContinue
```

### Wrong profile

List the profile headings without displaying credentials:

```powershell
Select-String -Path "$HOME\.oci\config" -Pattern '^\[.+\]$'
```

Then run the command with the required profile:

```powershell
oci iam region list --profile DEV
```

### Authentication failure or fingerprint mismatch

Confirm that:

- `tenancy` and `user` contain the correct OCIDs.
- `fingerprint` matches the public API key uploaded to that OCI user.
- `key_file` points to the private key paired with that public key.
- The private key is a supported PEM key and its passphrase is configured if it
  is encrypted.
- The OCI user has policies granting the operation being attempted.

## Security Guidance

- Never commit the OCI config, private key, `.env` files, or real credential
  values to Git.
- Keep private keys under the user's `.oci` or another access-controlled
  directory.
- Use separate profiles and keys where environments or identities require
  isolation.
- Remove and replace an API key immediately if its private key is exposed.

For more information, see Oracle's
[SDK and CLI configuration file documentation](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/sdkconfig.htm)
and [API signing key documentation](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm).
