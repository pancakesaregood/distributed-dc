param(
  [string]$TerraformDir = "",
  [string]$AwsProfile = "",
  [string]$GcpCredentialsPath = "",
  [switch]$EnablePublishedAppPath,
  [switch]$EnableOpsStack,
  [switch]$EnableCloudflareEdge,
  [string]$CloudflareApiToken = "",
  [string]$CloudflareZoneId = "",
  [string]$CloudflareZoneName = "",
  [string]$CloudflareSiteARecordName = "",
  [string]$CloudflareSiteBRecordName = "",
  [string[]]$SiteAPublishedAppBackendTargets = @(),
  [string[]]$SiteBPublishedAppBackendTargets = @(),
  [int]$PublishedAppBackendPort = 0,
  [string]$PublishedAppHealthCheckPath = "",
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
$ingressInternetEdgeEnabled = $EnablePublishedAppPath.IsPresent.ToString().ToLowerInvariant()
$cloudflareEnabled = $EnableCloudflareEdge.IsPresent.ToString().ToLowerInvariant()
$vdiEnabled = $EnableVdiReferenceStack.IsPresent.ToString().ToLowerInvariant()
$opsEnabled = $EnableOpsStack.IsPresent.ToString().ToLowerInvariant()
$phase5Enabled = $EnablePhase5Flags.IsPresent.ToString().ToLowerInvariant()
$command = if ($PlanOnly) { "plan" } else { "apply" }

$hasCloudflareSiteA = -not [string]::IsNullOrWhiteSpace($CloudflareSiteARecordName)
$hasCloudflareSiteB = -not [string]::IsNullOrWhiteSpace($CloudflareSiteBRecordName)
if ($EnableCloudflareEdge) {
  if ([string]::IsNullOrWhiteSpace($CloudflareApiToken)) {
    $CloudflareApiToken = $env:CLOUDFLARE_API_TOKEN
  }

  if ([string]::IsNullOrWhiteSpace($CloudflareApiToken)) {
    throw "CloudflareApiToken is required when -EnableCloudflareEdge is set. Pass -CloudflareApiToken or set CLOUDFLARE_API_TOKEN."
  }

  if ([string]::IsNullOrWhiteSpace($CloudflareZoneId) -and [string]::IsNullOrWhiteSpace($CloudflareZoneName)) {
    throw "CloudflareZoneId or CloudflareZoneName is required when -EnableCloudflareEdge is set."
  }

  if (-not $hasCloudflareSiteA -and -not $hasCloudflareSiteB) {
    throw "At least one of CloudflareSiteARecordName or CloudflareSiteBRecordName is required when -EnableCloudflareEdge is set."
  }
}

$existingTfVarCloudflareToken = $env:TF_VAR_cloudflare_api_token
$hadTfVarCloudflareToken = (Test-Path Env:TF_VAR_cloudflare_api_token)

$temporaryVarFile = ""
$overrideVariables = [ordered]@{}
if ($PSBoundParameters.ContainsKey("SiteAPublishedAppBackendTargets")) {
  $overrideVariables["phase4_site_a_published_app_backend_ipv4_targets"] = @($SiteAPublishedAppBackendTargets)
}
if ($PSBoundParameters.ContainsKey("SiteBPublishedAppBackendTargets")) {
  $overrideVariables["phase4_site_b_published_app_backend_ipv4_targets"] = @($SiteBPublishedAppBackendTargets)
}
if ($PublishedAppBackendPort -gt 0) {
  $overrideVariables["phase4_published_app_backend_port"] = $PublishedAppBackendPort
}
if (-not [string]::IsNullOrWhiteSpace($PublishedAppHealthCheckPath)) {
  $overrideVariables["phase4_published_app_health_check_path"] = $PublishedAppHealthCheckPath
}
if ($overrideVariables.Count -gt 0) {
  $temporaryVarFile = Join-Path ([System.IO.Path]::GetTempPath()) ("ddc-dev-up-overrides-" + [guid]::NewGuid().ToString("N") + ".tfvars.json")
  $overrideVariables | ConvertTo-Json -Depth 20 | Set-Content -Path $temporaryVarFile
}

$args = @(
  $command,
  "-var", "phase2_enable_intercloud=true",
  "-var", "phase3_enable_platform=true",
  "-var", "phase4_enable_service_onboarding=true",
  "-var", "phase4_enable_published_app_path=$publishedEnabled",
  "-var", "phase4_aws_enable_ingress_internet_edge=$ingressInternetEdgeEnabled",
  "-var", "phase4_enable_cloudflare_edge=$cloudflareEnabled",
  "-var", "phase4_enable_vdi_reference_stack=$vdiEnabled",
  "-var", "phase4_enable_ops_stack=$opsEnabled",
  "-var", "phase5_enable_resilience_validation=$phase5Enabled",
  "-var", "phase5_enable_backup_restore_drills=$phase5Enabled",
  "-var", "phase5_enable_handover_signoff=$phase5Enabled"
)

if ($EnableCloudflareEdge) {
  if (-not [string]::IsNullOrWhiteSpace($CloudflareZoneId)) {
    $args += @("-var", "phase4_cloudflare_zone_id=$CloudflareZoneId")
  }
  if (-not [string]::IsNullOrWhiteSpace($CloudflareZoneName)) {
    $args += @("-var", "phase4_cloudflare_zone_name=$CloudflareZoneName")
  }
  if ($hasCloudflareSiteA) {
    $args += @("-var", "phase4_cloudflare_site_a_record_name=$CloudflareSiteARecordName")
  }
  if ($hasCloudflareSiteB) {
    $args += @("-var", "phase4_cloudflare_site_b_record_name=$CloudflareSiteBRecordName")
  }
}

if (-not [string]::IsNullOrWhiteSpace($temporaryVarFile)) {
  $args += @("-var-file", $temporaryVarFile)
}

if (-not $PlanOnly -and $AutoApprove) {
  $args += "-auto-approve"
}

Push-Location $TerraformDir
try {
  if ($EnableCloudflareEdge) {
    $env:TF_VAR_cloudflare_api_token = $CloudflareApiToken
  }

  if (-not $SkipInit) {
    Invoke-Terraform -Executable $terraform -Arguments @("init")
  }

  Write-Host "Starting dev environment with Phase 3/4 enabled."
  Write-Host "Inter-cloud VPN/BGP: true"
  Write-Host "Published app path: $publishedEnabled"
  Write-Host "AWS ingress internet edge: $ingressInternetEdgeEnabled"
  if ($EnablePublishedAppPath) {
    Write-Host ("Published app targets site-a: {0}; site-b: {1}; backend_port={2}; health_path={3}" -f $SiteAPublishedAppBackendTargets.Count, $SiteBPublishedAppBackendTargets.Count, $PublishedAppBackendPort, $PublishedAppHealthCheckPath)
  }
  Write-Host "Cloudflare edge: $cloudflareEnabled"
  Write-Host "VDI reference stack: $vdiEnabled"
  Write-Host "Ops server stack: $opsEnabled"
  Invoke-Terraform -Executable $terraform -Arguments $args
} finally {
  Pop-Location
  if ($EnableCloudflareEdge) {
    if ($hadTfVarCloudflareToken) {
      $env:TF_VAR_cloudflare_api_token = $existingTfVarCloudflareToken
    } else {
      Remove-Item Env:TF_VAR_cloudflare_api_token -ErrorAction SilentlyContinue
    }
  }
  if (-not [string]::IsNullOrWhiteSpace($temporaryVarFile) -and (Test-Path $temporaryVarFile)) {
    Remove-Item -Path $temporaryVarFile -Force -ErrorAction SilentlyContinue
  }
}
