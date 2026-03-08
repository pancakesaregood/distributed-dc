param(
  [string]$TerraformDir = "",
  [string]$AwsProfile = "",
  [string]$GcpCredentialsPath = "",
  [string]$GcpProjectId = "",
  [string]$SiteANodegroupName = "",
  [string]$SiteBNodegroupName = "",
  [string]$NodegroupSuffix = "vdi",
  [int]$MaxTargetsPerSite = 4,
  [int]$PublishedAppBackendPort = 30080,
  [string]$PublishedAppHealthCheckPath = "/guacamole/",
  [switch]$AllowEmptyTargets,
  [switch]$EnablePublishedAppTls,
  [switch]$EnableCloudflareEdge,
  [string]$CloudflareApiToken = "",
  [string]$CloudflareZoneId = "",
  [string]$CloudflareZoneName = "",
  [string]$CloudflareSiteARecordName = "",
  [string]$CloudflareSiteBRecordName = "",
  [switch]$CloudflareRecordProxied,
  [int]$CloudflareRecordTtl = 0,
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

function Get-UniqueTextTokens {
  param(
    [string]$Value
  )

  return @(
    ($Value -split "\s+") |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and $_ -ne "None" } |
    ForEach-Object { $_.Trim() } |
    Sort-Object -Unique
  )
}

function Get-EksNodegroupPrivateIps {
  param(
    [Parameter(Mandatory = $true)]
    [string]$AwsExecutable,
    [Parameter(Mandatory = $true)]
    [string]$ClusterName,
    [Parameter(Mandatory = $true)]
    [string]$NodegroupName,
    [Parameter(Mandatory = $true)]
    [string]$Region,
    [int]$MaxTargets = 4,
    [string]$AwsProfileName = ""
  )

  $ngArgs = @(
    "eks", "describe-nodegroup",
    "--cluster-name", $ClusterName,
    "--nodegroup-name", $NodegroupName,
    "--region", $Region,
    "--query", "nodegroup.resources.autoScalingGroups[].name",
    "--output", "text"
  )
  if (-not [string]::IsNullOrWhiteSpace($AwsProfileName)) {
    $ngArgs += @("--profile", $AwsProfileName)
  }

  $ngResult = Invoke-NativeCommandCapture -Executable $AwsExecutable -Arguments $ngArgs
  if ($ngResult.exit_code -ne 0) {
    throw "Unable to describe nodegroup '$NodegroupName' in cluster '$ClusterName' ($Region). Error: $($ngResult.output)"
  }

  $asgNames = Get-UniqueTextTokens -Value $ngResult.output
  if ($asgNames.Count -eq 0) {
    return @()
  }

  $asgArgs = @(
    "autoscaling", "describe-auto-scaling-groups",
    "--region", $Region,
    "--auto-scaling-group-names"
  )
  $asgArgs += $asgNames
  $asgArgs += @(
    "--query", "AutoScalingGroups[].Instances[?LifecycleState=='InService'].InstanceId",
    "--output", "text"
  )
  if (-not [string]::IsNullOrWhiteSpace($AwsProfileName)) {
    $asgArgs += @("--profile", $AwsProfileName)
  }

  $asgResult = Invoke-NativeCommandCapture -Executable $AwsExecutable -Arguments $asgArgs
  if ($asgResult.exit_code -ne 0) {
    throw "Unable to inspect ASG instances for nodegroup '$NodegroupName' in region '$Region'. Error: $($asgResult.output)"
  }

  $instanceIds = Get-UniqueTextTokens -Value $asgResult.output
  if ($instanceIds.Count -eq 0) {
    return @()
  }

  $ec2Args = @(
    "ec2", "describe-instances",
    "--region", $Region,
    "--instance-ids"
  )
  $ec2Args += $instanceIds
  $ec2Args += @(
    "--query", "Reservations[].Instances[?State.Name=='running'].PrivateIpAddress",
    "--output", "text"
  )
  if (-not [string]::IsNullOrWhiteSpace($AwsProfileName)) {
    $ec2Args += @("--profile", $AwsProfileName)
  }

  $ec2Result = Invoke-NativeCommandCapture -Executable $AwsExecutable -Arguments $ec2Args
  if ($ec2Result.exit_code -ne 0) {
    throw "Unable to resolve node private IPs for nodegroup '$NodegroupName' in region '$Region'. Error: $($ec2Result.output)"
  }

  $privateIps = Get-UniqueTextTokens -Value $ec2Result.output
  if ($MaxTargets -gt 0 -and $privateIps.Count -gt $MaxTargets) {
    $privateIps = @($privateIps | Select-Object -First $MaxTargets)
  }

  return @($privateIps)
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

  $siteARegion = Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "aws_site_a_region" -DefaultValue "us-east-1"
  $siteBRegion = Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "aws_site_b_region" -DefaultValue "us-west-2"

  $namePrefix = Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "name_prefix" -DefaultValue "ddc"
  $environment = Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "environment" -DefaultValue "proposal"
  $siteACluster = "$namePrefix-$environment-site-a-eks"
  $siteBCluster = "$namePrefix-$environment-site-b-eks"
  try {
    $phase3Aws = Get-TerraformOutputJson -TerraformExecutable $terraform -OutputName "phase3_aws_eks_clusters"
    if ($null -ne $phase3Aws.site_a -and -not [string]::IsNullOrWhiteSpace($phase3Aws.site_a.cluster_name)) {
      $siteACluster = $phase3Aws.site_a.cluster_name
    }
    if ($null -ne $phase3Aws.site_b -and -not [string]::IsNullOrWhiteSpace($phase3Aws.site_b.cluster_name)) {
      $siteBCluster = $phase3Aws.site_b.cluster_name
    }
  } catch {
    Write-Warning "Unable to resolve phase3_aws_eks_clusters from Terraform outputs; using naming fallback."
  }

  if ([string]::IsNullOrWhiteSpace($SiteANodegroupName)) {
    $SiteANodegroupName = $siteACluster -replace "-eks$", "-ng-$NodegroupSuffix"
  }
  if ([string]::IsNullOrWhiteSpace($SiteBNodegroupName)) {
    $SiteBNodegroupName = $siteBCluster -replace "-eks$", "-ng-$NodegroupSuffix"
  }

  Write-Host "Discovering EKS nodegroup private IP targets..."
  Write-Host "Site A cluster/nodegroup/region: $siteACluster / $SiteANodegroupName / $siteARegion"
  Write-Host "Site B cluster/nodegroup/region: $siteBCluster / $SiteBNodegroupName / $siteBRegion"

  $siteATargets = Get-EksNodegroupPrivateIps -AwsExecutable $aws -ClusterName $siteACluster -NodegroupName $SiteANodegroupName -Region $siteARegion -MaxTargets $MaxTargetsPerSite -AwsProfileName $AwsProfile
  $siteBTargets = Get-EksNodegroupPrivateIps -AwsExecutable $aws -ClusterName $siteBCluster -NodegroupName $SiteBNodegroupName -Region $siteBRegion -MaxTargets $MaxTargetsPerSite -AwsProfileName $AwsProfile

  Write-Host ("Discovered Site A EKS backend targets ({0}): {1}" -f $siteATargets.Count, (($siteATargets -join ", ").Trim()))
  Write-Host ("Discovered Site B EKS backend targets ({0}): {1}" -f $siteBTargets.Count, (($siteBTargets -join ", ").Trim()))

  if (-not $AllowEmptyTargets) {
    if ($siteATargets.Count -eq 0) {
      throw "No site-a EKS backend targets discovered from nodegroup '$SiteANodegroupName'. Use -AllowEmptyTargets to continue."
    }
    if ($siteBTargets.Count -eq 0) {
      throw "No site-b EKS backend targets discovered from nodegroup '$SiteBNodegroupName'. Use -AllowEmptyTargets to continue."
    }
  } elseif ($siteATargets.Count -eq 0 -or $siteBTargets.Count -eq 0) {
    Write-Warning "One or both sites have zero discovered EKS targets; listener may remain unavailable."
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
    if ($CloudflareRecordProxied) {
      $phase4Params.CloudflareRecordProxied = $true
    }
    if ($CloudflareRecordTtl -gt 0) {
      $phase4Params.CloudflareRecordTtl = $CloudflareRecordTtl
    }
  }
  if ($EnablePublishedAppTls) {
    $phase4Params.EnablePublishedAppTls = $true
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

  Write-Host "Invoking invoke_phase4_vdi_enablement.ps1 with EKS-discovered backend targets."
  & $phase4EnablementScript @phase4Params
} finally {
  Pop-Location
}
