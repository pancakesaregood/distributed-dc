param(
  [string]$TerraformDir = "",
  [string]$AwsProfile = "",
  [string]$GcpCredentialsPath = "",
  [string]$GcpProjectId = "",
  [bool]$IncludeDataSubnets = $true,
  [bool]$IncludeIngressSubnets = $false,
  [int]$MaxTargetsPerSite = 4,
  [int]$PublishedAppBackendPort = 80,
  [string]$PublishedAppHealthCheckPath = "/healthz",
  [switch]$AllowEmptyTargets,
  [switch]$EnableCloudflareEdge,
  [string]$CloudflareApiToken = "",
  [string]$CloudflareZoneId = "",
  [string]$CloudflareZoneName = "",
  [string]$CloudflareSiteARecordName = "",
  [string]$CloudflareSiteBRecordName = "",
  [switch]$DisableGcpBrokerIdentity,
  [switch]$DisableAwsWorkerPools,
  [switch]$DisableGcpWorkerPools,
  [switch]$SkipInit,
  [switch]$PlanOnly,
  [switch]$PreflightOnly,
  [switch]$SkipHealthChecks,
  [switch]$FailOnUnhealthy,
  [switch]$AutoApprove
)

$ErrorActionPreference = "Stop"
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
  $PSNativeCommandUseErrorActionPreference = $false
}

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

function Invoke-NativeCommandCapture {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Executable,
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments
  )

  $previousPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = "Continue"
    $output = & $Executable @Arguments 2>&1
    $exitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousPreference
  }

  return [pscustomobject]@{
    exit_code = $exitCode
    output    = ($output | Out-String).Trim()
  }
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

function Get-TfvarsStringValue {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TerraformDirectory,
    [Parameter(Mandatory = $true)]
    [string]$VariableName,
    [Parameter(Mandatory = $true)]
    [string]$DefaultValue
  )

  $tfvarsPath = Join-Path $TerraformDirectory "terraform.tfvars"
  if (-not (Test-Path $tfvarsPath)) {
    return $DefaultValue
  }

  $raw = Get-Content -Path $tfvarsPath -Raw
  $pattern = "(?m)^\s*" + [regex]::Escape($VariableName) + "\s*=\s*""([^""]+)"""
  $match = [regex]::Match($raw, $pattern)
  if ($match.Success) {
    return $match.Groups[1].Value
  }

  return $DefaultValue
}

function Get-TerraformOutputJson {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TerraformExecutable,
    [Parameter(Mandatory = $true)]
    [string]$OutputName
  )

  $result = Invoke-NativeCommandCapture -Executable $TerraformExecutable -Arguments @("output", "-json", $OutputName)
  if ($result.exit_code -ne 0) {
    throw "terraform output -json $OutputName failed: $($result.output)"
  }

  try {
    return ($result.output | ConvertFrom-Json)
  } catch {
    throw "Unable to parse terraform output '$OutputName' as JSON. Error: $($_.Exception.Message)"
  }
}

function Test-IsValidIpv4Address {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Value
  )

  $parsed = [System.Net.IPAddress]$null
  if (-not [System.Net.IPAddress]::TryParse($Value, [ref]$parsed)) {
    return $false
  }

  return $parsed.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork
}

function Get-AwsPrivateIpTargets {
  param(
    [Parameter(Mandatory = $true)]
    [string]$AwsExecutable,
    [Parameter(Mandatory = $true)]
    [string[]]$SubnetIds,
    [Parameter(Mandatory = $true)]
    [string]$Region,
    [int]$MaxTargets = 4,
    [string]$AwsProfileName = ""
  )

  $cleanSubnetIds = @(
    $SubnetIds |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { $_.Trim() } |
    Sort-Object -Unique
  )
  if ($cleanSubnetIds.Count -eq 0) {
    return @()
  }

  $subnetFilter = ($cleanSubnetIds -join ",")
  $args = @(
    "ec2", "describe-network-interfaces",
    "--region", $Region,
    "--filters", "Name=subnet-id,Values=$subnetFilter", "Name=status,Values=in-use",
    "--query", "NetworkInterfaces[].PrivateIpAddress",
    "--output", "text"
  )
  if (-not [string]::IsNullOrWhiteSpace($AwsProfileName)) {
    $args += @("--profile", $AwsProfileName)
  }

  $result = Invoke-NativeCommandCapture -Executable $AwsExecutable -Arguments $args
  if ($result.exit_code -ne 0) {
    throw "AWS private IP target discovery failed in region '$Region' for subnets [$($cleanSubnetIds -join ', ')]. Error: $($result.output)"
  }

  $rawTokens = @($result.output -split "\s+")
  $ipTargets = @(
    $rawTokens |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-IsValidIpv4Address -Value $_.Trim()) } |
    ForEach-Object { $_.Trim() } |
    Sort-Object -Unique
  )

  if ($MaxTargets -gt 0 -and $ipTargets.Count -gt $MaxTargets) {
    $ipTargets = @($ipTargets | Select-Object -First $MaxTargets)
  }

  return @($ipTargets)
}

if ([string]::IsNullOrWhiteSpace($TerraformDir)) {
  $TerraformDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

if (-not (Test-Path $TerraformDir)) {
  throw "TerraformDir does not exist: $TerraformDir"
}

if ($MaxTargetsPerSite -lt 0) {
  throw "MaxTargetsPerSite must be >= 0."
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

$aws = Get-ToolPath -Name "aws"
if ($null -eq $aws) {
  throw "aws CLI not found in PATH."
}

$phase4EnablementScript = Join-Path $PSScriptRoot "invoke_phase4_vdi_enablement.ps1"
if (-not (Test-Path $phase4EnablementScript)) {
  throw "Expected script not found: $phase4EnablementScript"
}

Push-Location $TerraformDir
try {
  if (-not $SkipInit) {
    Invoke-Terraform -Executable $terraform -Arguments @("init")
  }

  Invoke-Terraform -Executable $terraform -Arguments @("validate")

  $siteANetwork = Get-TerraformOutputJson -TerraformExecutable $terraform -OutputName "aws_site_a_network"
  $siteBNetwork = Get-TerraformOutputJson -TerraformExecutable $terraform -OutputName "aws_site_b_network"

  $siteARegion = Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "aws_site_a_region" -DefaultValue "us-east-1"
  $siteBRegion = Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "aws_site_b_region" -DefaultValue "us-west-2"

  $siteASubnets = @($siteANetwork.app_subnets)
  $siteBSubnets = @($siteBNetwork.app_subnets)
  if ($IncludeDataSubnets) {
    $siteASubnets += @($siteANetwork.data_subnets)
    $siteBSubnets += @($siteBNetwork.data_subnets)
  }
  if ($IncludeIngressSubnets) {
    $siteASubnets += @($siteANetwork.ingress_subnets)
    $siteBSubnets += @($siteBNetwork.ingress_subnets)
  }

  $siteASubnets = @($siteASubnets | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
  $siteBSubnets = @($siteBSubnets | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)

  if ($siteASubnets.Count -eq 0 -or $siteBSubnets.Count -eq 0) {
    throw "Unable to resolve app/data subnet IDs for one or both AWS sites from Terraform outputs."
  }

  Write-Host "Discovering backend targets from AWS private ENI IPs..."
  Write-Host "Site A region/subnets: $siteARegion / $($siteASubnets -join ', ')"
  Write-Host "Site B region/subnets: $siteBRegion / $($siteBSubnets -join ', ')"

  $siteATargets = Get-AwsPrivateIpTargets -AwsExecutable $aws -SubnetIds $siteASubnets -Region $siteARegion -MaxTargets $MaxTargetsPerSite -AwsProfileName $AwsProfile
  $siteBTargets = Get-AwsPrivateIpTargets -AwsExecutable $aws -SubnetIds $siteBSubnets -Region $siteBRegion -MaxTargets $MaxTargetsPerSite -AwsProfileName $AwsProfile

  Write-Host ("Discovered Site A backend targets ({0}): {1}" -f $siteATargets.Count, (($siteATargets -join ", ").Trim()))
  Write-Host ("Discovered Site B backend targets ({0}): {1}" -f $siteBTargets.Count, (($siteBTargets -join ", ").Trim()))

  if (-not $AllowEmptyTargets) {
    if ($siteATargets.Count -eq 0) {
      throw "No site-a backend targets discovered. Use -AllowEmptyTargets to continue in fixed-response mode."
    }
    if ($siteBTargets.Count -eq 0) {
      throw "No site-b backend targets discovered. Use -AllowEmptyTargets to continue in fixed-response mode."
    }
  } elseif ($siteATargets.Count -eq 0 -or $siteBTargets.Count -eq 0) {
    Write-Warning "One or both sites have zero discovered targets; published app listener may stay fixed-response (503)."
  }

  if ([string]::IsNullOrWhiteSpace($CloudflareApiToken)) {
    $CloudflareApiToken = $env:CLOUDFLARE_API_TOKEN
  }
  if (-not [string]::IsNullOrWhiteSpace($CloudflareApiToken)) {
    $CloudflareApiToken = $CloudflareApiToken.Trim().Trim("'").Trim('"')
  }

  $phase4Params = @{
    TerraformDir                     = $TerraformDir
    EnablePublishedAppPath           = $true
    SiteAPublishedAppBackendTargets  = @($siteATargets)
    SiteBPublishedAppBackendTargets  = @($siteBTargets)
    PublishedAppBackendPort          = $PublishedAppBackendPort
    PublishedAppHealthCheckPath      = $PublishedAppHealthCheckPath
    SkipInit                         = $true
  }

  if (-not [string]::IsNullOrWhiteSpace($AwsProfile)) {
    $phase4Params.AwsProfile = $AwsProfile
  }
  if (-not [string]::IsNullOrWhiteSpace($GcpCredentialsPath)) {
    $phase4Params.GcpCredentialsPath = $GcpCredentialsPath
  }
  if (-not [string]::IsNullOrWhiteSpace($GcpProjectId)) {
    $phase4Params.GcpProjectId = $GcpProjectId
  }
  if ($EnableCloudflareEdge) {
    $phase4Params.EnableCloudflareEdge = $true
    if (-not [string]::IsNullOrWhiteSpace($CloudflareApiToken)) {
      $phase4Params.CloudflareApiToken = $CloudflareApiToken
    }
    if (-not [string]::IsNullOrWhiteSpace($CloudflareZoneId)) {
      $phase4Params.CloudflareZoneId = $CloudflareZoneId
    }
    if (-not [string]::IsNullOrWhiteSpace($CloudflareZoneName)) {
      $phase4Params.CloudflareZoneName = $CloudflareZoneName
    }
    if (-not [string]::IsNullOrWhiteSpace($CloudflareSiteARecordName)) {
      $phase4Params.CloudflareSiteARecordName = $CloudflareSiteARecordName
    }
    if (-not [string]::IsNullOrWhiteSpace($CloudflareSiteBRecordName)) {
      $phase4Params.CloudflareSiteBRecordName = $CloudflareSiteBRecordName
    }
  }
  if ($DisableGcpBrokerIdentity) {
    $phase4Params.DisableGcpBrokerIdentity = $true
  }
  if ($DisableAwsWorkerPools) {
    $phase4Params.DisableAwsWorkerPools = $true
  }
  if ($DisableGcpWorkerPools) {
    $phase4Params.DisableGcpWorkerPools = $true
  }
  if ($PlanOnly) {
    $phase4Params.PlanOnly = $true
  }
  if ($PreflightOnly) {
    $phase4Params.PreflightOnly = $true
  }
  if ($SkipHealthChecks) {
    $phase4Params.SkipHealthChecks = $true
  }
  if ($FailOnUnhealthy) {
    $phase4Params.FailOnUnhealthy = $true
  }
  if ($AutoApprove) {
    $phase4Params.AutoApprove = $true
  }

  Write-Host "Invoking invoke_phase4_vdi_enablement.ps1 with discovered backend targets."
  & $phase4EnablementScript @phase4Params
} finally {
  Pop-Location
}
