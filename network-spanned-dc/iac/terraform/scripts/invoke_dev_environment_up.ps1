param(
  [string]$TerraformDir = "",
  [string]$AwsProfile = "",
  [string]$GcpCredentialsPath = "",
  [switch]$EnablePublishedAppPath,
  [switch]$EnableVdiReferenceStack,
  [switch]$EnablePhase5Flags,
  [switch]$PlanOnly,
  [switch]$SkipInit,
  [switch]$AutoApprove
)

$ErrorActionPreference = "Stop"

function Get-TerraformCmd {
  $cmd = Get-Command terraform -ErrorAction SilentlyContinue
  if ($null -eq $cmd) {
    throw "terraform not found in PATH."
  }
  return $cmd.Source
}

function Invoke-Terraform {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Executable,
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments
  )

  Write-Host "terraform $($Arguments -join ' ')"
  & $Executable @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "terraform command failed with exit code $LASTEXITCODE"
  }
}

if ([string]::IsNullOrWhiteSpace($TerraformDir)) {
  $TerraformDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

if (-not (Test-Path $TerraformDir)) {
  throw "TerraformDir does not exist: $TerraformDir"
}

if (-not [string]::IsNullOrWhiteSpace($AwsProfile)) {
  $env:AWS_PROFILE = $AwsProfile
}

if (-not [string]::IsNullOrWhiteSpace($GcpCredentialsPath)) {
  if (-not (Test-Path $GcpCredentialsPath)) {
    throw "GCP credentials file not found: $GcpCredentialsPath"
  }
  $env:GOOGLE_APPLICATION_CREDENTIALS = $GcpCredentialsPath
}

$terraform = Get-TerraformCmd
$publishedEnabled = $EnablePublishedAppPath.IsPresent.ToString().ToLowerInvariant()
$vdiEnabled = $EnableVdiReferenceStack.IsPresent.ToString().ToLowerInvariant()
$phase5Enabled = $EnablePhase5Flags.IsPresent.ToString().ToLowerInvariant()
$command = if ($PlanOnly) { "plan" } else { "apply" }

$args = @(
  $command,
  "-var", "phase2_enable_intercloud=true",
  "-var", "phase3_enable_platform=true",
  "-var", "phase4_enable_service_onboarding=true",
  "-var", "phase4_enable_published_app_path=$publishedEnabled",
  "-var", "phase4_enable_vdi_reference_stack=$vdiEnabled",
  "-var", "phase5_enable_resilience_validation=$phase5Enabled",
  "-var", "phase5_enable_backup_restore_drills=$phase5Enabled",
  "-var", "phase5_enable_handover_signoff=$phase5Enabled"
)

if (-not $PlanOnly -and $AutoApprove) {
  $args += "-auto-approve"
}

Push-Location $TerraformDir
try {
  if (-not $SkipInit) {
    Invoke-Terraform -Executable $terraform -Arguments @("init")
  }

  Write-Host "Starting dev environment with Phase 3/4 enabled."
  Write-Host "Inter-cloud VPN/BGP: true"
  Write-Host "Published app path: $publishedEnabled"
  Write-Host "VDI reference stack: $vdiEnabled"
  Invoke-Terraform -Executable $terraform -Arguments $args
} finally {
  Pop-Location
}
