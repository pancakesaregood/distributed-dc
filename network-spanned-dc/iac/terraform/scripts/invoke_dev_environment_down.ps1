param(
  [string]$TerraformDir = "",
  [string]$AwsProfile = "",
  [string]$GcpCredentialsPath = "",
  [switch]$DestroyAll,
  [switch]$SuspendIntercloud,
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

Push-Location $TerraformDir
try {
  if (-not $SkipInit) {
    Invoke-Terraform -Executable $terraform -Arguments @("init")
  }

  if ($DestroyAll) {
    if ($PlanOnly) {
      Write-Host "Previewing full destroy plan."
      Invoke-Terraform -Executable $terraform -Arguments @("plan", "-destroy")
    } else {
      $destroyArgs = @("destroy")
      if ($AutoApprove) {
        $destroyArgs += "-auto-approve"
      }
      Write-Host "Destroying all Terraform-managed resources (maximum cost savings)."
      Invoke-Terraform -Executable $terraform -Arguments $destroyArgs
    }
  } else {
    $intercloudEnabled = (-not $SuspendIntercloud.IsPresent).ToString().ToLowerInvariant()
    $command = if ($PlanOnly) { "plan" } else { "apply" }
    $args = @(
      $command,
      "-var", "phase2_enable_intercloud=$intercloudEnabled",
      "-var", "phase3_enable_platform=false",
      "-var", "phase4_enable_service_onboarding=false",
      "-var", "phase4_enable_published_app_path=false",
      "-var", "phase4_enable_vdi_reference_stack=false",
      "-var", "phase5_enable_resilience_validation=false",
      "-var", "phase5_enable_backup_restore_drills=false",
      "-var", "phase5_enable_handover_signoff=false"
    )

    if (-not $PlanOnly -and $AutoApprove) {
      $args += "-auto-approve"
    }

    if ($SuspendIntercloud) {
      Write-Host "Stopping expensive platform resources and suspending Phase 2 inter-cloud VPN/BGP."
    } else {
      Write-Host "Stopping expensive platform resources while keeping base networking in place."
    }
    Invoke-Terraform -Executable $terraform -Arguments $args
  }
} finally {
  Pop-Location
}
