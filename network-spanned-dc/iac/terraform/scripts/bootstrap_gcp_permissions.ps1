param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectId,

  [string]$ServiceAccountName = "terraform-ddc",

  [string]$KeyOutputPath = "",

  [switch]$EnableGkeRoles
)

$ErrorActionPreference = "Stop"

function Get-GcloudCmd {
  $candidates = @(
    "gcloud",
    "$env:LOCALAPPDATA\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd",
    "C:\Program Files\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
  )

  foreach ($candidate in $candidates) {
    try {
      if ($candidate -eq "gcloud") {
        $cmd = Get-Command gcloud -ErrorAction Stop
        return $cmd.Source
      }
      if (Test-Path $candidate) {
        return $candidate
      }
    } catch {
      continue
    }
  }

  throw "gcloud not found. Install Google Cloud SDK first."
}

function Invoke-Gcloud {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Args
  )

  Write-Host "gcloud $($Args -join ' ')"
  & $script:GcloudCmd @Args
  if ($LASTEXITCODE -ne 0) {
    throw "gcloud command failed with exit code $LASTEXITCODE"
  }
}

$script:GcloudCmd = Get-GcloudCmd
$firstAccount = & $script:GcloudCmd auth list --format="value(account)" 2>$null | Select-Object -First 1
$activeAccount = if ($null -ne $firstAccount) { $firstAccount.ToString().Trim() } else { "" }

if ([string]::IsNullOrWhiteSpace($activeAccount) -or $activeAccount -eq "(unset)") {
  throw "No active gcloud account. Run: gcloud auth login"
}

$serviceAccountEmail = "$ServiceAccountName@$ProjectId.iam.gserviceaccount.com"

Invoke-Gcloud -Args @("config", "set", "project", $ProjectId)
Invoke-Gcloud -Args @("services", "enable", "compute.googleapis.com", "iam.googleapis.com", "serviceusage.googleapis.com")

if ($EnableGkeRoles) {
  Invoke-Gcloud -Args @("services", "enable", "container.googleapis.com")
}

$saExists = $false
try {
  & $script:GcloudCmd iam service-accounts describe $serviceAccountEmail --project $ProjectId 1>$null 2>$null
  if ($LASTEXITCODE -eq 0) { $saExists = $true }
} catch {
  $saExists = $false
}

if (-not $saExists) {
  Invoke-Gcloud -Args @("iam", "service-accounts", "create", $ServiceAccountName, "--display-name", "Terraform DDC", "--project", $ProjectId)
}

$roles = @(
  "roles/compute.networkAdmin",
  "roles/compute.securityAdmin"
)

if ($EnableGkeRoles) {
  $roles += @(
    "roles/container.admin",
    "roles/iam.serviceAccountUser"
  )
}

foreach ($role in $roles) {
  Invoke-Gcloud -Args @(
    "projects", "add-iam-policy-binding", $ProjectId,
    "--member=serviceAccount:$serviceAccountEmail",
    "--role=$role"
  )
}

if (-not [string]::IsNullOrWhiteSpace($KeyOutputPath)) {
  $keyDir = Split-Path -Path $KeyOutputPath -Parent
  if (-not (Test-Path $keyDir)) {
    New-Item -ItemType Directory -Path $keyDir -Force | Out-Null
  }

  if (Test-Path $KeyOutputPath) {
    Write-Host "Key file already exists at $KeyOutputPath. Skipping key creation."
  } else {
    Invoke-Gcloud -Args @(
      "iam", "service-accounts", "keys", "create", $KeyOutputPath,
      "--iam-account", $serviceAccountEmail
    )
  }
}

Write-Host ""
Write-Host "Bootstrap complete."
Write-Host "Service account: $serviceAccountEmail"
if (-not [string]::IsNullOrWhiteSpace($KeyOutputPath)) {
  Write-Host "Set env var in your terminal:"
  Write-Host "`$env:GOOGLE_APPLICATION_CREDENTIALS=`"$KeyOutputPath`""
}
