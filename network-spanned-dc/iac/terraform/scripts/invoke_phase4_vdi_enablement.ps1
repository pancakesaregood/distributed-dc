param(
  [string]$TerraformDir = "",
  [string]$AwsProfile = "",
  [string]$GcpCredentialsPath = "",
  [string]$GcpProjectId = "",
  [switch]$EnablePublishedAppPath,
  [switch]$PlanOnly,
  [switch]$SkipInit,
  [switch]$SkipHealthChecks,
  [switch]$AutoApprove,
  [switch]$FailOnUnhealthy
)

$ErrorActionPreference = "Stop"

function Get-ToolPath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($null -eq $cmd) {
    return $null
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

function Get-TerraformOutputJson {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TerraformExecutable,
    [Parameter(Mandatory = $true)]
    [string]$OutputName
  )

  $json = & $TerraformExecutable output -json $OutputName
  if ($LASTEXITCODE -ne 0) {
    throw "terraform output failed for '$OutputName' with exit code $LASTEXITCODE"
  }

  return ($json | ConvertFrom-Json)
}

function Resolve-GcpProjectId {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TerraformExecutable,
    [string]$ProvidedProjectId = ""
  )

  if (-not [string]::IsNullOrWhiteSpace($ProvidedProjectId)) {
    return $ProvidedProjectId
  }

  try {
    $gcpSiteC = Get-TerraformOutputJson -TerraformExecutable $TerraformExecutable -OutputName "gcp_site_c_network"
    if ($null -ne $gcpSiteC -and -not [string]::IsNullOrWhiteSpace($gcpSiteC.network_self_link)) {
      if ($gcpSiteC.network_self_link -match "/projects/([^/]+)/") {
        return $Matches[1]
      }
    }
  } catch {
    # Fall back to env/gcloud config.
  }

  if (-not [string]::IsNullOrWhiteSpace($env:GOOGLE_CLOUD_PROJECT)) {
    return $env:GOOGLE_CLOUD_PROJECT
  }

  if (-not [string]::IsNullOrWhiteSpace($env:CLOUDSDK_CORE_PROJECT)) {
    return $env:CLOUDSDK_CORE_PROJECT
  }

  $gcloud = Get-ToolPath -Name "gcloud"
  if ($null -ne $gcloud) {
    $projectFromConfig = & $gcloud config get-value project 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($projectFromConfig) -and $projectFromConfig -ne "(unset)") {
      return $projectFromConfig.Trim()
    }
  }

  return ""
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

$terraform = Get-ToolPath -Name "terraform"
if ($null -eq $terraform) {
  throw "terraform not found in PATH."
}

$publishedEnabled = $EnablePublishedAppPath.IsPresent.ToString().ToLowerInvariant()
$command = if ($PlanOnly) { "plan" } else { "apply" }

$args = @(
  $command,
  "-var", "phase2_enable_intercloud=true",
  "-var", "phase3_enable_platform=true",
  "-var", "phase4_enable_service_onboarding=true",
  "-var", "phase4_enable_published_app_path=$publishedEnabled",
  "-var", "phase4_enable_vdi_reference_stack=true",
  "-var", "phase5_enable_resilience_validation=false",
  "-var", "phase5_enable_backup_restore_drills=false",
  "-var", "phase5_enable_handover_signoff=false"
)

if (-not $PlanOnly -and $AutoApprove) {
  $args += "-auto-approve"
}

Push-Location $TerraformDir
try {
  if (-not $SkipInit) {
    Invoke-Terraform -Executable $terraform -Arguments @("init")
  }

  Write-Host "Enabling Phase 4 VDI reference stack."
  Write-Host "Published app path: $publishedEnabled"
  Invoke-Terraform -Executable $terraform -Arguments $args

  if ($PlanOnly -or $SkipHealthChecks) {
    if ($PlanOnly) {
      Write-Host "Plan-only mode: skipping post-apply health checks."
    } else {
      Write-Host "Skipping post-apply health checks by request."
    }
    return
  }

  $aws = Get-ToolPath -Name "aws"
  $gcloud = Get-ToolPath -Name "gcloud"
  if ($null -eq $aws -or $null -eq $gcloud) {
    $missing = @()
    if ($null -eq $aws) { $missing += "aws" }
    if ($null -eq $gcloud) { $missing += "gcloud" }
    $message = "Cannot run health checks because CLI tools are missing: $($missing -join ', ')"
    if ($FailOnUnhealthy) {
      throw $message
    }
    Write-Warning $message
    return
  }

  $phase4Vdi = Get-TerraformOutputJson -TerraformExecutable $terraform -OutputName "phase4_vdi_reference_stacks"
  $phase3Aws = Get-TerraformOutputJson -TerraformExecutable $terraform -OutputName "phase3_aws_eks_clusters"
  $projectId = Resolve-GcpProjectId -TerraformExecutable $terraform -ProvidedProjectId $GcpProjectId

  if ([string]::IsNullOrWhiteSpace($projectId)) {
    $message = "GCP project ID could not be resolved for health checks. Pass -GcpProjectId explicitly."
    if ($FailOnUnhealthy) {
      throw $message
    }
    Write-Warning $message
    return
  }

  $awsChecks = @(
    [pscustomobject]@{
      site      = "site-a"
      cluster   = $phase4Vdi.aws.site_a.worker.cluster_name
      nodegroup = $phase4Vdi.aws.site_a.worker.node_group_name
      region    = ([regex]::Match($phase3Aws.site_a.cluster_arn, "arn:aws:eks:([^:]+):")).Groups[1].Value
    },
    [pscustomobject]@{
      site      = "site-b"
      cluster   = $phase4Vdi.aws.site_b.worker.cluster_name
      nodegroup = $phase4Vdi.aws.site_b.worker.node_group_name
      region    = ([regex]::Match($phase3Aws.site_b.cluster_arn, "arn:aws:eks:([^:]+):")).Groups[1].Value
    }
  )

  $gcpChecks = @(
    [pscustomobject]@{
      site     = "site-c"
      cluster  = $phase4Vdi.gcp.site_c.worker.cluster_name
      nodepool = $phase4Vdi.gcp.site_c.worker.node_pool
      location = $phase4Vdi.gcp.site_c.worker.location
    },
    [pscustomobject]@{
      site     = "site-d"
      cluster  = $phase4Vdi.gcp.site_d.worker.cluster_name
      nodepool = $phase4Vdi.gcp.site_d.worker.node_pool
      location = $phase4Vdi.gcp.site_d.worker.location
    }
  )

  $unhealthy = New-Object System.Collections.Generic.List[string]

  foreach ($check in $awsChecks) {
    $awsArgs = @("eks", "describe-nodegroup", "--cluster-name", $check.cluster, "--nodegroup-name", $check.nodegroup, "--region", $check.region, "--output", "json")
    if (-not [string]::IsNullOrWhiteSpace($AwsProfile)) {
      $awsArgs += @("--profile", $AwsProfile)
    }

    $awsResult = & $aws @awsArgs
    if ($LASTEXITCODE -ne 0) {
      $unhealthy.Add("AWS $($check.site): failed to query nodegroup '$($check.nodegroup)'.")
      continue
    }

    $nodegroup = ($awsResult | ConvertFrom-Json).nodegroup
    $status = $nodegroup.status
    Write-Host ("AWS {0}: nodegroup {1} status={2}" -f $check.site, $check.nodegroup, $status)
    if ($status -ne "ACTIVE") {
      $unhealthy.Add("AWS $($check.site): nodegroup '$($check.nodegroup)' status is '$status' (expected ACTIVE).")
    }
  }

  foreach ($check in $gcpChecks) {
    $gcpArgs = @("container", "node-pools", "describe", $check.nodepool, "--cluster", $check.cluster, "--location", $check.location, "--project", $projectId, "--format", "value(status)")
    $status = (& $gcloud @gcpArgs 2>$null).Trim()
    if ($LASTEXITCODE -ne 0) {
      $unhealthy.Add("GCP $($check.site): failed to query node pool '$($check.nodepool)'.")
      continue
    }

    Write-Host ("GCP {0}: nodepool {1} status={2}" -f $check.site, $check.nodepool, $status)
    if ($status -ne "RUNNING") {
      $unhealthy.Add("GCP $($check.site): node pool '$($check.nodepool)' status is '$status' (expected RUNNING).")
    }
  }

  if ($unhealthy.Count -gt 0) {
    foreach ($msg in $unhealthy) {
      Write-Warning $msg
    }

    if ($FailOnUnhealthy) {
      throw "One or more VDI worker health checks failed."
    }
  } else {
    Write-Host "Phase 4 VDI worker health checks passed."
  }
} finally {
  Pop-Location
}
