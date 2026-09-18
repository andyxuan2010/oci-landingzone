$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Push-Location $repoRoot
try {
  Write-Host "====================================================" -ForegroundColor Cyan
  Write-Host "terraform fmt -check -recursive" -ForegroundColor Cyan
  terraform fmt -check -recursive

  Write-Host "====================================================" -ForegroundColor Cyan
  Write-Host "terraform init -backend=false" -ForegroundColor Cyan
  terraform init -backend=false -input=false -no-color | Out-Null

  Write-Host "====================================================" -ForegroundColor Cyan
  Write-Host "terraform validate" -ForegroundColor Cyan
  terraform validate -no-color
}
finally {
  Pop-Location
}
