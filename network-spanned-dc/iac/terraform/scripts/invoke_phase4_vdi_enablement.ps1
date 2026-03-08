param(
  [string]$TerraformDir = "",
  [string]$AwsProfile = "",
  [string]$GcpCredentialsPath = "",
  [string]$GcpProjectId = "",
  [switch]$EnablePublishedAppPath,
  [switch]$EnablePublishedAppTls,
  [switch]$EnableCloudflareEdge,
  [string]$CloudflareApiToken = "",
  [string]$CloudflareZoneId = "",
  [string]$CloudflareZoneName = "",
  [string]$CloudflareSiteARecordName = "",
  [string]$CloudflareSiteBRecordName = "",
  [switch]$CloudflareRecordProxied,
  [int]$CloudflareRecordTtl = 0,
  [string[]]$SiteAPublishedAppBackendTargets = @(),
  [string[]]$SiteBPublishedAppBackendTargets = @(),
  [int]$PublishedAppBackendPort = 0,
  [string]$PublishedAppHealthCheckPath = "",
  [switch]$PlanOnly,
  [switch]$PreflightOnly,
  [switch]$SkipInit,
  [switch]$SkipHealthChecks,
  [switch]$SkipAwsFreeTierChecks,
  [switch]$SkipAwsExistingNodegroupChecks,
  [switch]$SkipGcpQuotaChecks,
  [switch]$DisableGcpBrokerIdentity,
  [switch]$DisableAwsWorkerPools,
  [switch]$DisableGcpWorkerPools,
  [switch]$AutoApprove,
  [switch]$FailOnUnhealthy,
  [bool]$CollectDiagnosticsOnFailure = $true,
  [int]$HealthCheckTimeoutMinutes = 20,
  [int]$HealthCheckPollSeconds = 30,
  [string]$DiagnosticsDir = ""
)

$ErrorActionPreference = "Stop"
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
  $PSNativeCommandUseErrorActionPreference = $false
}

function Write-Stage {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Message
  )

  Write-Host ""
  Write-Host "== $Message =="
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

function Get-TfvarsStringValue {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TerraformDirectory,
    [Parameter(Mandatory = $true)]
    [string]$VariableName,
    [AllowEmptyString()]
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

function Get-TfvarsStringListValue {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TerraformDirectory,
    [Parameter(Mandatory = $true)]
    [string]$VariableName,
    [Parameter(Mandatory = $true)]
    [string[]]$DefaultValues
  )

  $tfvarsPath = Join-Path $TerraformDirectory "terraform.tfvars"
  if (-not (Test-Path $tfvarsPath)) {
    return @($DefaultValues)
  }

  $raw = Get-Content -Path $tfvarsPath -Raw
  $pattern = "(?ms)^\s*" + [regex]::Escape($VariableName) + "\s*=\s*\[(?<list>.*?)\]"
  $match = [regex]::Match($raw, $pattern)
  if (-not $match.Success) {
    return @($DefaultValues)
  }

  $values = New-Object System.Collections.Generic.List[string]
  $itemMatches = [regex]::Matches($match.Groups["list"].Value, '"([^"]+)"')
  foreach ($item in $itemMatches) {
    $values.Add($item.Groups[1].Value)
  }

  if ($values.Count -eq 0) {
    return @($DefaultValues)
  }

  return $values.ToArray()
}

function Get-TfvarsNumberValue {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TerraformDirectory,
    [Parameter(Mandatory = $true)]
    [string]$VariableName,
    [Parameter(Mandatory = $true)]
    [double]$DefaultValue
  )

  $tfvarsPath = Join-Path $TerraformDirectory "terraform.tfvars"
  if (-not (Test-Path $tfvarsPath)) {
    return $DefaultValue
  }

  $raw = Get-Content -Path $tfvarsPath -Raw
  $pattern = "(?m)^\s*" + [regex]::Escape($VariableName) + "\s*=\s*(-?\d+(\.\d+)?)\s*$"
  $match = [regex]::Match($raw, $pattern)
  if (-not $match.Success) {
    return $DefaultValue
  }

  [double]$parsed = 0
  if ([double]::TryParse($match.Groups[1].Value, [ref]$parsed)) {
    return $parsed
  }

  return $DefaultValue
}

function Get-TfvarsBoolValue {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TerraformDirectory,
    [Parameter(Mandatory = $true)]
    [string]$VariableName,
    [Parameter(Mandatory = $true)]
    [bool]$DefaultValue
  )

  $tfvarsPath = Join-Path $TerraformDirectory "terraform.tfvars"
  if (-not (Test-Path $tfvarsPath)) {
    return $DefaultValue
  }

  $raw = Get-Content -Path $tfvarsPath -Raw
  $pattern = "(?m)^\s*" + [regex]::Escape($VariableName) + "\s*=\s*(true|false)\s*$"
  $match = [regex]::Match($raw, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  if (-not $match.Success) {
    return $DefaultValue
  }

  return $match.Groups[1].Value.ToLowerInvariant() -eq "true"
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

function Test-AwsVpcContainsPrivateIp {
  param(
    [Parameter(Mandatory = $true)]
    [string]$AwsExecutable,
    [Parameter(Mandatory = $true)]
    [string]$VpcId,
    [Parameter(Mandatory = $true)]
    [string]$IpAddress,
    [Parameter(Mandatory = $true)]
    [string]$Region,
    [string]$AwsProfileName = ""
  )

  $args = @(
    "ec2", "describe-network-interfaces",
    "--region", $Region,
    "--filters", "Name=vpc-id,Values=$VpcId", "Name=addresses.private-ip-address,Values=$IpAddress",
    "--query", "NetworkInterfaces[0].NetworkInterfaceId",
    "--output", "text"
  )
  if (-not [string]::IsNullOrWhiteSpace($AwsProfileName)) {
    $args += @("--profile", $AwsProfileName)
  }

  $result = Invoke-NativeCommandCapture -Executable $AwsExecutable -Arguments $args
  if ($result.exit_code -ne 0) {
    return [pscustomobject]@{
      ok      = $false
      message = "Unable to resolve backend IP '$IpAddress' in VPC '$VpcId'. AWS CLI error: $($result.output)"
    }
  }

  $eni = $result.output.Trim()
  if ([string]::IsNullOrWhiteSpace($eni) -or $eni -eq "None") {
    return [pscustomobject]@{
      ok      = $false
      message = "Backend IP '$IpAddress' is not currently attached to a known ENI in VPC '$VpcId'."
    }
  }

  return [pscustomobject]@{
    ok      = $true
    message = "Backend IP '$IpAddress' is attached to ENI '$eni'."
  }
}

function Get-AwsNodegroupInfo {
  param(
    [Parameter(Mandatory = $true)]
    [string]$AwsExecutable,
    [Parameter(Mandatory = $true)]
    [string]$ClusterName,
    [Parameter(Mandatory = $true)]
    [string]$NodegroupName,
    [Parameter(Mandatory = $true)]
    [string]$Region,
    [string]$AwsProfileName = ""
  )

  $args = @("eks", "describe-nodegroup", "--cluster-name", $ClusterName, "--nodegroup-name", $NodegroupName, "--region", $Region, "--output", "json")
  if (-not [string]::IsNullOrWhiteSpace($AwsProfileName)) {
    $args += @("--profile", $AwsProfileName)
  }

  $result = Invoke-NativeCommandCapture -Executable $AwsExecutable -Arguments $args
  $text = $result.output
  if ($result.exit_code -ne 0) {
    if ($text -match "ResourceNotFoundException|No node group found|not found") {
      return [pscustomobject]@{
        exists    = $false
        status    = $null
        nodegroup = $null
        error     = $null
        raw       = $text
      }
    }

    return [pscustomobject]@{
      exists    = $false
      status    = $null
      nodegroup = $null
      error     = $text
      raw       = $text
    }
  }

  $nodegroup = ($text | ConvertFrom-Json).nodegroup
  return [pscustomobject]@{
    exists    = $true
    status    = $nodegroup.status
    nodegroup = $nodegroup
    error     = $null
    raw       = $text
  }
}

function Get-AwsNodegroupFailureHint {
  param(
    [Parameter(Mandatory = $true)]
    [string]$AwsExecutable,
    [Parameter(Mandatory = $true)]
    [string]$NodegroupName,
    [Parameter(Mandatory = $true)]
    [string]$Region,
    [string]$AwsProfileName = ""
  )

  $asgQuery = "AutoScalingGroups[?contains(Tags[?Key=='eks:nodegroup-name'].Value | [0], '$NodegroupName')].AutoScalingGroupName | [0]"
  $asgArgs = @("autoscaling", "describe-auto-scaling-groups", "--region", $Region, "--query", $asgQuery, "--output", "text")
  if (-not [string]::IsNullOrWhiteSpace($AwsProfileName)) {
    $asgArgs += @("--profile", $AwsProfileName)
  }

  $asgResult = Invoke-NativeCommandCapture -Executable $AwsExecutable -Arguments $asgArgs
  $asgName = $asgResult.output.Trim()
  if ($asgResult.exit_code -ne 0 -or [string]::IsNullOrWhiteSpace($asgName) -or $asgName -eq "None") {
    return ""
  }

  $activityArgs = @(
    "autoscaling", "describe-scaling-activities",
    "--region", $Region,
    "--auto-scaling-group-name", $asgName,
    "--max-items", "1",
    "--query", "Activities[0].Description",
    "--output", "text"
  )
  if (-not [string]::IsNullOrWhiteSpace($AwsProfileName)) {
    $activityArgs += @("--profile", $AwsProfileName)
  }

  $activityResult = Invoke-NativeCommandCapture -Executable $AwsExecutable -Arguments $activityArgs
  $activity = $activityResult.output.Trim()
  if ($activityResult.exit_code -ne 0 -or [string]::IsNullOrWhiteSpace($activity) -or $activity -eq "None") {
    return ""
  }

  return "ASG '$asgName' latest activity: $activity"
}

function Test-AwsInstanceTypesFreeTierEligible {
  param(
    [Parameter(Mandatory = $true)]
    [string]$AwsExecutable,
    [Parameter(Mandatory = $true)]
    [string[]]$InstanceTypes,
    [Parameter(Mandatory = $true)]
    [string]$Region,
    [Parameter(Mandatory = $true)]
    [string]$Label,
    [string]$AwsProfileName = ""
  )

  $args = @(
    "ec2", "describe-instance-types",
    "--region", $Region,
    "--filters", "Name=free-tier-eligible,Values=true",
    "--query", "InstanceTypes[].InstanceType",
    "--output", "text"
  )
  if (-not [string]::IsNullOrWhiteSpace($AwsProfileName)) {
    $args += @("--profile", $AwsProfileName)
  }

  $result = Invoke-NativeCommandCapture -Executable $AwsExecutable -Arguments $args
  $text = $result.output
  if ($result.exit_code -ne 0) {
    return [pscustomobject]@{
      ok      = $false
      message = "Unable to check free-tier instance types in region '$Region' for $Label. AWS CLI error: $text"
    }
  }

  $eligibleSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
  foreach ($token in ($text -split "\s+")) {
    if (-not [string]::IsNullOrWhiteSpace($token)) {
      [void]$eligibleSet.Add($token.Trim())
    }
  }

  $invalid = New-Object System.Collections.Generic.List[string]
  foreach ($instanceType in $InstanceTypes) {
    if (-not $eligibleSet.Contains($instanceType)) {
      $invalid.Add($instanceType)
    }
  }

  if ($invalid.Count -eq 0) {
    return [pscustomobject]@{
      ok      = $true
      message = "Free-tier check passed for $Label in $Region."
    }
  }

  $eligibleList = ($eligibleSet.ToArray() | Sort-Object) -join ", "
  $invalidList = ($invalid.ToArray() | Sort-Object) -join ", "
  return [pscustomobject]@{
    ok      = $false
    message = "Free-tier check failed for $Label in $Region. Configured types not eligible: $invalidList. Eligible in region: $eligibleList"
  }
}

function Get-AwsSubnetRouteTableId {
  param(
    [Parameter(Mandatory = $true)]
    [string]$AwsExecutable,
    [Parameter(Mandatory = $true)]
    [string]$VpcId,
    [Parameter(Mandatory = $true)]
    [string]$SubnetId,
    [Parameter(Mandatory = $true)]
    [string]$Region,
    [string]$AwsProfileName = ""
  )

  $subnetArgs = @(
    "ec2", "describe-route-tables",
    "--region", $Region,
    "--filters", "Name=association.subnet-id,Values=$SubnetId",
    "--query", "RouteTables[0].RouteTableId",
    "--output", "text"
  )
  if (-not [string]::IsNullOrWhiteSpace($AwsProfileName)) {
    $subnetArgs += @("--profile", $AwsProfileName)
  }

  $subnetResult = Invoke-NativeCommandCapture -Executable $AwsExecutable -Arguments $subnetArgs
  if ($subnetResult.exit_code -ne 0) {
    return [pscustomobject]@{
      ok      = $false
      message = "Unable to query route table association for subnet '$SubnetId'. AWS CLI error: $($subnetResult.output)"
      value   = ""
    }
  }

  $subnetRouteTableId = $subnetResult.output.Trim()
  if (-not [string]::IsNullOrWhiteSpace($subnetRouteTableId) -and $subnetRouteTableId -ne "None") {
    return [pscustomobject]@{
      ok      = $true
      message = ""
      value   = $subnetRouteTableId
    }
  }

  $mainArgs = @(
    "ec2", "describe-route-tables",
    "--region", $Region,
    "--filters", "Name=vpc-id,Values=$VpcId", "Name=association.main,Values=true",
    "--query", "RouteTables[0].RouteTableId",
    "--output", "text"
  )
  if (-not [string]::IsNullOrWhiteSpace($AwsProfileName)) {
    $mainArgs += @("--profile", $AwsProfileName)
  }

  $mainResult = Invoke-NativeCommandCapture -Executable $AwsExecutable -Arguments $mainArgs
  if ($mainResult.exit_code -ne 0) {
    return [pscustomobject]@{
      ok      = $false
      message = "Unable to query main route table for VPC '$VpcId'. AWS CLI error: $($mainResult.output)"
      value   = ""
    }
  }

  $mainRouteTableId = $mainResult.output.Trim()
  if ([string]::IsNullOrWhiteSpace($mainRouteTableId) -or $mainRouteTableId -eq "None") {
    return [pscustomobject]@{
      ok      = $false
      message = "No route table was resolved for subnet '$SubnetId' in VPC '$VpcId'."
      value   = ""
    }
  }

  return [pscustomobject]@{
    ok      = $true
    message = ""
    value   = $mainRouteTableId
  }
}

function Test-AwsIngressSubnetInternetEdge {
  param(
    [Parameter(Mandatory = $true)]
    [string]$AwsExecutable,
    [Parameter(Mandatory = $true)]
    [string]$Site,
    [Parameter(Mandatory = $true)]
    [string]$VpcId,
    [Parameter(Mandatory = $true)]
    [string[]]$IngressSubnetIds,
    [Parameter(Mandatory = $true)]
    [string]$Region,
    [string]$AwsProfileName = ""
  )

  if ([string]::IsNullOrWhiteSpace($VpcId)) {
    return [pscustomobject]@{
      ok      = $false
      message = "AWS ${Site}: VPC ID is missing."
    }
  }

  if ($IngressSubnetIds.Count -eq 0) {
    return [pscustomobject]@{
      ok      = $false
      message = "AWS ${Site}: ingress subnet IDs are missing."
    }
  }

  $igwArgs = @(
    "ec2", "describe-internet-gateways",
    "--region", $Region,
    "--filters", "Name=attachment.vpc-id,Values=$VpcId",
    "--query", "InternetGateways[].InternetGatewayId",
    "--output", "text"
  )
  if (-not [string]::IsNullOrWhiteSpace($AwsProfileName)) {
    $igwArgs += @("--profile", $AwsProfileName)
  }

  $igwResult = Invoke-NativeCommandCapture -Executable $AwsExecutable -Arguments $igwArgs
  if ($igwResult.exit_code -ne 0) {
    return [pscustomobject]@{
      ok      = $false
      message = "AWS ${Site}: unable to query internet gateways for VPC '$VpcId'. AWS CLI error: $($igwResult.output)"
    }
  }

  $igwSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
  foreach ($token in ($igwResult.output -split "\s+")) {
    $candidate = $token.Trim()
    if (-not [string]::IsNullOrWhiteSpace($candidate) -and $candidate -ne "None") {
      [void]$igwSet.Add($candidate)
    }
  }

  if ($igwSet.Count -eq 0) {
    return [pscustomobject]@{
      ok      = $false
      message = "AWS ${Site}: no internet gateway is attached to VPC '$VpcId'."
    }
  }

  foreach ($subnetId in $IngressSubnetIds) {
    $routeTableResult = Get-AwsSubnetRouteTableId -AwsExecutable $AwsExecutable -VpcId $VpcId -SubnetId $subnetId -Region $Region -AwsProfileName $AwsProfileName
    if (-not $routeTableResult.ok) {
      return [pscustomobject]@{
        ok      = $false
        message = "AWS ${Site}: $($routeTableResult.message)"
      }
    }

    $routeTableId = $routeTableResult.value
    $routeArgs = @(
      "ec2", "describe-route-tables",
      "--region", $Region,
      "--route-table-ids", $routeTableId,
      "--query", "RouteTables[0].Routes[?DestinationCidrBlock=='0.0.0.0/0'].GatewayId | [0]",
      "--output", "text"
    )
    if (-not [string]::IsNullOrWhiteSpace($AwsProfileName)) {
      $routeArgs += @("--profile", $AwsProfileName)
    }

    $routeResult = Invoke-NativeCommandCapture -Executable $AwsExecutable -Arguments $routeArgs
    if ($routeResult.exit_code -ne 0) {
      return [pscustomobject]@{
        ok      = $false
        message = "AWS ${Site}: unable to inspect default route for route table '$routeTableId'. AWS CLI error: $($routeResult.output)"
      }
    }

    $gatewayId = $routeResult.output.Trim()
    if ([string]::IsNullOrWhiteSpace($gatewayId) -or $gatewayId -eq "None") {
      return [pscustomobject]@{
        ok      = $false
        message = "AWS ${Site}: ingress subnet '$subnetId' route table '$routeTableId' lacks 0.0.0.0/0 route."
      }
    }

    if (-not $gatewayId.StartsWith("igw-")) {
      return [pscustomobject]@{
        ok      = $false
        message = "AWS ${Site}: ingress subnet '$subnetId' route table '$routeTableId' default route does not target an internet gateway (gateway='$gatewayId')."
      }
    }

    if (-not $igwSet.Contains($gatewayId)) {
      return [pscustomobject]@{
        ok      = $false
        message = "AWS ${Site}: ingress subnet '$subnetId' default route points to '$gatewayId', but that gateway is not attached to VPC '$VpcId'."
      }
    }
  }

  return [pscustomobject]@{
    ok      = $true
    message = "AWS ${Site}: ingress internet edge check passed for VPC '$VpcId'."
  }
}

function Get-GcpProjectCpuQuota {
  param(
    [Parameter(Mandatory = $true)]
    [string]$GcloudExecutable,
    [Parameter(Mandatory = $true)]
    [string]$ProjectId
  )

  $args = @("compute", "project-info", "describe", "--project", $ProjectId, "--format", "json(quotas)")
  $result = Invoke-NativeCommandCapture -Executable $GcloudExecutable -Arguments $args
  if ($result.exit_code -ne 0) {
    return [pscustomobject]@{
      ok      = $false
      message = "Unable to query GCP project quotas. gcloud error: $($result.output)"
    }
  }

  $json = $result.output | ConvertFrom-Json
  $quota = $json.quotas | Where-Object { $_.metric -eq "CPUS_ALL_REGIONS" } | Select-Object -First 1
  if ($null -eq $quota) {
    return [pscustomobject]@{
      ok      = $false
      message = "Quota metric 'CPUS_ALL_REGIONS' was not returned by gcloud for project '$ProjectId'."
    }
  }

  $limit = [double]$quota.limit
  $usage = [double]$quota.usage
  $available = $limit - $usage
  return [pscustomobject]@{
    ok        = $true
    limit     = $limit
    usage     = $usage
    available = $available
  }
}

function Get-GcpClusterLocationMetadata {
  param(
    [Parameter(Mandatory = $true)]
    [string]$GcloudExecutable,
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,
    [Parameter(Mandatory = $true)]
    [string]$ClusterName,
    [Parameter(Mandatory = $true)]
    [string]$Location
  )

  $args = @("container", "clusters", "describe", $ClusterName, "--location", $Location, "--project", $ProjectId, "--format", "json(location,locations)")
  $result = Invoke-NativeCommandCapture -Executable $GcloudExecutable -Arguments $args
  if ($result.exit_code -ne 0) {
    return [pscustomobject]@{
      ok      = $false
      message = "Unable to describe GKE cluster '$ClusterName' in '$Location'. gcloud error: $($result.output)"
    }
  }

  $json = $result.output | ConvertFrom-Json
  $locations = @()
  if ($null -ne $json.locations) {
    $locations = @($json.locations)
  }

  $count = if ($locations.Count -gt 0) { $locations.Count } else { 1 }
  $zoneHint = if ($locations.Count -gt 0) { $locations[0] } else { "$Location-a" }
  return [pscustomobject]@{
    ok              = $true
    location_count  = $count
    zone_hint       = $zoneHint
    cluster_location = $Location
  }
}

function Get-GcpMachineTypeGuestCpus {
  param(
    [Parameter(Mandatory = $true)]
    [string]$GcloudExecutable,
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,
    [Parameter(Mandatory = $true)]
    [string]$MachineType,
    [Parameter(Mandatory = $true)]
    [string]$Zone
  )

  $args = @("compute", "machine-types", "describe", $MachineType, "--zone", $Zone, "--project", $ProjectId, "--format", "value(guestCpus)")
  $result = Invoke-NativeCommandCapture -Executable $GcloudExecutable -Arguments $args
  if ($result.exit_code -ne 0) {
    return [pscustomobject]@{
      ok      = $false
      message = "Unable to resolve guest CPUs for machine type '$MachineType' in zone '$Zone'. gcloud error: $($result.output)"
    }
  }

  $raw = $result.output.Trim()
  [double]$guestCpus = 0
  if (-not [double]::TryParse($raw, [ref]$guestCpus)) {
    return [pscustomobject]@{
      ok      = $false
      message = "Unexpected guest CPU value '$raw' for machine type '$MachineType' in zone '$Zone'."
    }
  }

  return [pscustomobject]@{
    ok         = $true
    guest_cpus = $guestCpus
  }
}

function Test-GcpVdiCpuQuota {
  param(
    [Parameter(Mandatory = $true)]
    [string]$GcloudExecutable,
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,
    [Parameter(Mandatory = $true)]
    [string]$MachineType,
    [Parameter(Mandatory = $true)]
    [double]$InitialNodeCount,
    [Parameter(Mandatory = $true)]
    [pscustomobject[]]$GcpClusterChecks
  )

  if ($InitialNodeCount -le 0) {
    return [pscustomobject]@{
      ok      = $true
      message = "GCP quota check skipped because phase4_vdi_gcp_node_initial_count is <= 0."
    }
  }

  $quota = Get-GcpProjectCpuQuota -GcloudExecutable $GcloudExecutable -ProjectId $ProjectId
  if (-not $quota.ok) {
    return [pscustomobject]@{
      ok      = $false
      message = $quota.message
    }
  }

  $requiredTotal = 0.0
  $details = New-Object System.Collections.Generic.List[string]
  foreach ($check in $GcpClusterChecks) {
    $clusterMeta = Get-GcpClusterLocationMetadata -GcloudExecutable $GcloudExecutable -ProjectId $ProjectId -ClusterName $check.cluster -Location $check.location
    if (-not $clusterMeta.ok) {
      return [pscustomobject]@{
        ok      = $false
        message = $clusterMeta.message
      }
    }

    $cpuMeta = Get-GcpMachineTypeGuestCpus -GcloudExecutable $GcloudExecutable -ProjectId $ProjectId -MachineType $MachineType -Zone $clusterMeta.zone_hint
    if (-not $cpuMeta.ok) {
      return [pscustomobject]@{
        ok      = $false
        message = $cpuMeta.message
      }
    }

    $requiredForCluster = $cpuMeta.guest_cpus * $InitialNodeCount * $clusterMeta.location_count
    $requiredTotal += $requiredForCluster
    $details.Add(("{0}: machine={1}, guest_cpus={2}, locations={3}, initial_nodes={4}, required_cpus={5}" -f $check.site, $MachineType, $cpuMeta.guest_cpus, $clusterMeta.location_count, $InitialNodeCount, $requiredForCluster))
  }

  $detailText = $details.ToArray() -join "; "
  if ($requiredTotal -gt $quota.available) {
    return [pscustomobject]@{
      ok      = $false
      message = ("GCP quota check failed for CPUS_ALL_REGIONS. Required={0}, Available={1}, Limit={2}, Usage={3}. Details: {4}" -f $requiredTotal, $quota.available, $quota.limit, $quota.usage, $detailText)
    }
  }

  return [pscustomobject]@{
    ok      = $true
    message = ("GCP quota check passed for CPUS_ALL_REGIONS. Required={0}, Available={1}. Details: {2}" -f $requiredTotal, $quota.available, $detailText)
  }
}

function Wait-ForAwsNodegroupActive {
  param(
    [Parameter(Mandatory = $true)]
    [string]$AwsExecutable,
    [Parameter(Mandatory = $true)]
    [pscustomobject]$Check,
    [int]$TimeoutMinutes = 20,
    [int]$PollSeconds = 30,
    [string]$AwsProfileName = ""
  )

  $deadline = (Get-Date).AddMinutes($TimeoutMinutes)
  do {
    $info = Get-AwsNodegroupInfo -AwsExecutable $AwsExecutable -ClusterName $Check.cluster -NodegroupName $Check.nodegroup -Region $Check.region -AwsProfileName $AwsProfileName
    if ($null -ne $info.error) {
      return [pscustomobject]@{
        healthy = $false
        message = "AWS $($Check.site): failed to query nodegroup '$($Check.nodegroup)'. Error: $($info.error)"
      }
    }

    if (-not $info.exists) {
      return [pscustomobject]@{
        healthy = $false
        message = "AWS $($Check.site): nodegroup '$($Check.nodegroup)' does not exist."
      }
    }

    $status = $info.status
    Write-Host ("AWS {0}: nodegroup {1} status={2}" -f $Check.site, $Check.nodegroup, $status)
    if ($status -eq "ACTIVE") {
      return [pscustomobject]@{
        healthy = $true
        message = "AWS $($Check.site): nodegroup '$($Check.nodegroup)' is ACTIVE."
      }
    }

    if ($status -in @("CREATE_FAILED", "DELETE_FAILED", "DEGRADED")) {
      break
    }

    Start-Sleep -Seconds $PollSeconds
  } while ((Get-Date) -lt $deadline)

  $hint = Get-AwsNodegroupFailureHint -AwsExecutable $AwsExecutable -NodegroupName $Check.nodegroup -Region $Check.region -AwsProfileName $AwsProfileName
  if ([string]::IsNullOrWhiteSpace($hint)) {
    $hint = "No Auto Scaling hint available."
  }

  return [pscustomobject]@{
    healthy = $false
    message = "AWS $($Check.site): nodegroup '$($Check.nodegroup)' did not reach ACTIVE within $TimeoutMinutes minute(s). $hint"
  }
}

function Wait-ForGcpNodepoolRunning {
  param(
    [Parameter(Mandatory = $true)]
    [string]$GcloudExecutable,
    [Parameter(Mandatory = $true)]
    [pscustomobject]$Check,
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,
    [int]$TimeoutMinutes = 20,
    [int]$PollSeconds = 30
  )

  $deadline = (Get-Date).AddMinutes($TimeoutMinutes)
  do {
    $args = @("container", "node-pools", "describe", $Check.nodepool, "--cluster", $Check.cluster, "--location", $Check.location, "--project", $ProjectId, "--format", "value(status)")
    $statusResult = Invoke-NativeCommandCapture -Executable $GcloudExecutable -Arguments $args
    $status = $statusResult.output.Trim()
    if ($statusResult.exit_code -ne 0) {
      return [pscustomobject]@{
        healthy = $false
        message = "GCP $($Check.site): failed to query node pool '$($Check.nodepool)'. Error: $status"
      }
    }

    Write-Host ("GCP {0}: nodepool {1} status={2}" -f $Check.site, $Check.nodepool, $status)
    if ($status -eq "RUNNING") {
      return [pscustomobject]@{
        healthy = $true
        message = "GCP $($Check.site): node pool '$($Check.nodepool)' is RUNNING."
      }
    }

    Start-Sleep -Seconds $PollSeconds
  } while ((Get-Date) -lt $deadline)

  return [pscustomobject]@{
    healthy = $false
    message = "GCP $($Check.site): node pool '$($Check.nodepool)' did not reach RUNNING within $TimeoutMinutes minute(s)."
  }
}

function Write-VdiFailureDiagnostics {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TerraformDirectory,
    [string]$AwsExecutable = "",
    [string]$GcloudExecutable = "",
    [string]$AwsProfileName = "",
    [string]$ProjectId = "",
    [pscustomobject[]]$AwsChecks = @(),
    [pscustomobject[]]$GcpChecks = @(),
    [string]$Reason = "",
    [string]$OutputDirectory = ""
  )

  if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $TerraformDirectory "evidence\phase4-vdi-diagnostics"
  }

  New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
  $filePath = Join-Path $OutputDirectory ("phase4-vdi-diagnostic-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add("timestamp: $((Get-Date).ToString('o'))")
  if (-not [string]::IsNullOrWhiteSpace($Reason)) {
    $lines.Add("reason: $Reason")
  }
  $lines.Add("")

  foreach ($check in $AwsChecks) {
    $lines.Add(("aws/{0} cluster={1} nodegroup={2} region={3}" -f $check.site, $check.cluster, $check.nodegroup, $check.region))
    if ([string]::IsNullOrWhiteSpace($AwsExecutable)) {
      $lines.Add("  aws cli unavailable")
      $lines.Add("")
      continue
    }

    $info = Get-AwsNodegroupInfo -AwsExecutable $AwsExecutable -ClusterName $check.cluster -NodegroupName $check.nodegroup -Region $check.region -AwsProfileName $AwsProfileName
    if ($null -ne $info.error) {
      $lines.Add("  query_error: $($info.error)")
    } elseif (-not $info.exists) {
      $lines.Add("  status: NOT_FOUND")
    } else {
      $lines.Add("  status: $($info.status)")
      $hint = Get-AwsNodegroupFailureHint -AwsExecutable $AwsExecutable -NodegroupName $check.nodegroup -Region $check.region -AwsProfileName $AwsProfileName
      if (-not [string]::IsNullOrWhiteSpace($hint)) {
        $lines.Add("  hint: $hint")
      }
    }
    $lines.Add("")
  }

  foreach ($check in $GcpChecks) {
    $lines.Add(("gcp/{0} cluster={1} nodepool={2} location={3}" -f $check.site, $check.cluster, $check.nodepool, $check.location))
    if ([string]::IsNullOrWhiteSpace($GcloudExecutable) -or [string]::IsNullOrWhiteSpace($ProjectId)) {
      $lines.Add("  gcloud/project unavailable")
      $lines.Add("")
      continue
    }

    $args = @("container", "node-pools", "describe", $check.nodepool, "--cluster", $check.cluster, "--location", $check.location, "--project", $ProjectId, "--format", "value(status)")
    $statusResult = Invoke-NativeCommandCapture -Executable $GcloudExecutable -Arguments $args
    $status = $statusResult.output.Trim()
    if ($statusResult.exit_code -ne 0) {
      $lines.Add("  query_error: $status")
    } else {
      $lines.Add("  status: $status")
    }
    $lines.Add("")
  }

  $lines | Set-Content -Path $filePath
  Write-Warning "VDI diagnostics written to: $filePath"
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
$publishedTlsEnabled = $EnablePublishedAppTls.IsPresent.ToString().ToLowerInvariant()
$ingressInternetEdgeEnabled = $EnablePublishedAppPath.IsPresent.ToString().ToLowerInvariant()
$cloudflareEnabled = $EnableCloudflareEdge.IsPresent.ToString().ToLowerInvariant()
$command = if ($PlanOnly) { "plan" } else { "apply" }

$hasCloudflareSiteA = -not [string]::IsNullOrWhiteSpace($CloudflareSiteARecordName)
$hasCloudflareSiteB = -not [string]::IsNullOrWhiteSpace($CloudflareSiteBRecordName)
if ($EnableCloudflareEdge) {
  if (-not $EnablePublishedAppPath) {
    throw "-EnableCloudflareEdge requires -EnablePublishedAppPath."
  }

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

  if ($CloudflareRecordTtl -lt 0) {
    throw "CloudflareRecordTtl must be 0 (use tfvars/default), 1 (automatic), or >= 60."
  }
  if ($CloudflareRecordTtl -gt 0 -and $CloudflareRecordTtl -ne 1 -and $CloudflareRecordTtl -lt 60) {
    throw "CloudflareRecordTtl must be 1 (automatic) or >= 60 seconds."
  }
  if ($CloudflareRecordProxied -and $CloudflareRecordTtl -eq 0) {
    $CloudflareRecordTtl = 1
  }
}

if ($EnablePublishedAppTls -and -not $EnableCloudflareEdge) {
  throw "-EnablePublishedAppTls requires -EnableCloudflareEdge so DNS validation can be automated."
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
  $temporaryVarFile = Join-Path ([System.IO.Path]::GetTempPath()) ("ddc-phase4-overrides-" + [guid]::NewGuid().ToString("N") + ".tfvars.json")
  $overrideVariables | ConvertTo-Json -Depth 20 | Set-Content -Path $temporaryVarFile
}

$commonVarArgs = @(
  "-var", "phase2_enable_intercloud=true",
  "-var", "phase3_enable_platform=true",
  "-var", "phase4_enable_service_onboarding=true",
  "-var", "phase4_enable_published_app_path=$publishedEnabled",
  "-var", "phase4_enable_published_app_tls=$publishedTlsEnabled",
  "-var", "phase4_aws_enable_ingress_internet_edge=$ingressInternetEdgeEnabled",
  "-var", "phase4_enable_cloudflare_edge=$cloudflareEnabled",
  "-var", "phase4_enable_vdi_reference_stack=true",
  "-var", "phase5_enable_resilience_validation=false",
  "-var", "phase5_enable_backup_restore_drills=false",
  "-var", "phase5_enable_handover_signoff=false"
)

if ($EnableCloudflareEdge) {
  if (-not [string]::IsNullOrWhiteSpace($CloudflareZoneId)) {
    $commonVarArgs += @("-var", "phase4_cloudflare_zone_id=$CloudflareZoneId")
  }
  if (-not [string]::IsNullOrWhiteSpace($CloudflareZoneName)) {
    $commonVarArgs += @("-var", "phase4_cloudflare_zone_name=$CloudflareZoneName")
  }
  if ($hasCloudflareSiteA) {
    $commonVarArgs += @("-var", "phase4_cloudflare_site_a_record_name=$CloudflareSiteARecordName")
  }
  if ($hasCloudflareSiteB) {
    $commonVarArgs += @("-var", "phase4_cloudflare_site_b_record_name=$CloudflareSiteBRecordName")
  }
  if ($CloudflareRecordProxied) {
    $commonVarArgs += @("-var", "phase4_cloudflare_record_proxied=true")
  }
  if ($CloudflareRecordTtl -gt 0) {
    $commonVarArgs += @("-var", "phase4_cloudflare_record_ttl=$CloudflareRecordTtl")
  }
}

if (-not [string]::IsNullOrWhiteSpace($temporaryVarFile)) {
  $commonVarArgs += @("-var-file", $temporaryVarFile)
}

if ($DisableGcpBrokerIdentity) {
  $commonVarArgs += @("-var", "phase4_vdi_gcp_manage_broker_identity=false")
}

if ($DisableAwsWorkerPools) {
  $commonVarArgs += @("-var", "phase4_vdi_enable_aws_worker_pools=false")
}

if ($DisableGcpWorkerPools) {
  $commonVarArgs += @("-var", "phase4_vdi_enable_gcp_worker_pools=false")
}

$terraformArgs = @($command) + $commonVarArgs
if (-not $PlanOnly -and $AutoApprove) {
  $terraformArgs += "-auto-approve"
}

$awsChecks = @()
$gcpChecks = @()
$projectId = ""
$aws = Get-ToolPath -Name "aws"
$gcloud = Get-ToolPath -Name "gcloud"
$diagnosticsWritten = $false

Push-Location $TerraformDir
try {
  if ($EnableCloudflareEdge) {
    $env:TF_VAR_cloudflare_api_token = $CloudflareApiToken
  }

  if (-not $SkipInit) {
    Write-Stage -Message "Terraform Init"
    Invoke-Terraform -Executable $terraform -Arguments @("init")
  }

  Write-Stage -Message "Preflight"
  Invoke-Terraform -Executable $terraform -Arguments @("validate")

  $namePrefix = Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "name_prefix" -DefaultValue "ddc"
  $environment = Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "environment" -DefaultValue "proposal"
  $siteARegion = Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "aws_site_a_region" -DefaultValue "us-east-1"
  $siteBRegion = Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "aws_site_b_region" -DefaultValue "us-west-2"
  $siteACluster = "$namePrefix-$environment-site-a-eks"
  $siteBCluster = "$namePrefix-$environment-site-b-eks"
  $siteANodegroup = "$namePrefix-$environment-site-a-ng-vdi"
  $siteBNodegroup = "$namePrefix-$environment-site-b-ng-vdi"

  try {
    $phase3Aws = Get-TerraformOutputJson -TerraformExecutable $terraform -OutputName "phase3_aws_eks_clusters"
    if ($null -ne $phase3Aws.site_a) {
      $siteACluster = $phase3Aws.site_a.cluster_name
      if ($phase3Aws.site_a.cluster_arn -match "arn:aws:eks:([^:]+):") {
        $siteARegion = $Matches[1]
      }
      if ($siteACluster -match "-eks$") {
        $siteANodegroup = ($siteACluster -replace "-eks$", "-ng-vdi")
      }
    }
    if ($null -ne $phase3Aws.site_b) {
      $siteBCluster = $phase3Aws.site_b.cluster_name
      if ($phase3Aws.site_b.cluster_arn -match "arn:aws:eks:([^:]+):") {
        $siteBRegion = $Matches[1]
      }
      if ($siteBCluster -match "-eks$") {
        $siteBNodegroup = ($siteBCluster -replace "-eks$", "-ng-vdi")
      }
    }
  } catch {
    Write-Warning "Unable to read phase3_aws_eks_clusters from state; using tfvars/default naming."
  }

  $stateListRaw = & $terraform state list 2>$null
  $stateEntries = @()
  if ($LASTEXITCODE -eq 0) {
    $stateEntries = @($stateListRaw)
  }

  $awsChecks = @(
    [pscustomobject]@{
      site           = "site-a"
      cluster        = $siteACluster
      nodegroup      = $siteANodegroup
      region         = $siteARegion
      managedInState = ($stateEntries -contains "module.aws_eks_nodegroup_site_a_vdi[0].aws_eks_node_group.this")
    },
    [pscustomobject]@{
      site           = "site-b"
      cluster        = $siteBCluster
      nodegroup      = $siteBNodegroup
      region         = $siteBRegion
      managedInState = ($stateEntries -contains "module.aws_eks_nodegroup_site_b_vdi[0].aws_eks_node_group.this")
    }
  )

  $gcpSiteCRegion = Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "gcp_site_c_region" -DefaultValue "us-east4"
  $gcpSiteDRegion = Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "gcp_site_d_region" -DefaultValue "us-west1"
  $siteCCluster = "$namePrefix-$environment-site-c-gke"
  $siteDCluster = "$namePrefix-$environment-site-d-gke"

  try {
    $phase3Gcp = Get-TerraformOutputJson -TerraformExecutable $terraform -OutputName "phase3_gcp_gke_clusters"
    if ($null -ne $phase3Gcp.site_c) {
      $siteCCluster = $phase3Gcp.site_c.cluster_name
      if (-not [string]::IsNullOrWhiteSpace($phase3Gcp.site_c.location)) {
        $gcpSiteCRegion = $phase3Gcp.site_c.location
      }
    }
    if ($null -ne $phase3Gcp.site_d) {
      $siteDCluster = $phase3Gcp.site_d.cluster_name
      if (-not [string]::IsNullOrWhiteSpace($phase3Gcp.site_d.location)) {
        $gcpSiteDRegion = $phase3Gcp.site_d.location
      }
    }
  } catch {
    Write-Warning "Unable to read phase3_gcp_gke_clusters from state; using tfvars/default naming."
  }

  $gcpChecks = @(
    [pscustomobject]@{
      site     = "site-c"
      cluster  = $siteCCluster
      location = $gcpSiteCRegion
      nodepool = "$namePrefix-$environment-site-c-pool-vdi"
    },
    [pscustomobject]@{
      site     = "site-d"
      cluster  = $siteDCluster
      location = $gcpSiteDRegion
      nodepool = "$namePrefix-$environment-site-d-pool-vdi"
    }
  )

  $gcpProjectIdForPreflight = $GcpProjectId
  if ([string]::IsNullOrWhiteSpace($gcpProjectIdForPreflight)) {
    $gcpProjectIdForPreflight = Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "gcp_project_id" -DefaultValue ""
  }
  if ([string]::IsNullOrWhiteSpace($gcpProjectIdForPreflight)) {
    $gcpProjectIdForPreflight = Resolve-GcpProjectId -TerraformExecutable $terraform -ProvidedProjectId ""
  }
  if (-not [string]::IsNullOrWhiteSpace($gcpProjectIdForPreflight)) {
    $projectId = $gcpProjectIdForPreflight
  }

  $enableAwsVdiWorkers = if ($DisableAwsWorkerPools) { $false } else { Get-TfvarsBoolValue -TerraformDirectory $TerraformDir -VariableName "phase4_vdi_enable_aws_worker_pools" -DefaultValue $true }
  $enableGcpVdiWorkers = if ($DisableGcpWorkerPools) { $false } else { Get-TfvarsBoolValue -TerraformDirectory $TerraformDir -VariableName "phase4_vdi_enable_gcp_worker_pools" -DefaultValue $true }
  $defaultEmptyListSentinel = "__EMPTY_LIST__"
  $effectiveSiteAPublishedAppBackendTargets = if ($PSBoundParameters.ContainsKey("SiteAPublishedAppBackendTargets")) { @($SiteAPublishedAppBackendTargets) } else { @(Get-TfvarsStringListValue -TerraformDirectory $TerraformDir -VariableName "phase4_site_a_published_app_backend_ipv4_targets" -DefaultValues @($defaultEmptyListSentinel)) }
  $effectiveSiteBPublishedAppBackendTargets = if ($PSBoundParameters.ContainsKey("SiteBPublishedAppBackendTargets")) { @($SiteBPublishedAppBackendTargets) } else { @(Get-TfvarsStringListValue -TerraformDirectory $TerraformDir -VariableName "phase4_site_b_published_app_backend_ipv4_targets" -DefaultValues @($defaultEmptyListSentinel)) }
  if ($effectiveSiteAPublishedAppBackendTargets.Count -eq 1 -and $effectiveSiteAPublishedAppBackendTargets[0] -eq $defaultEmptyListSentinel) {
    $effectiveSiteAPublishedAppBackendTargets = @()
  }
  if ($effectiveSiteBPublishedAppBackendTargets.Count -eq 1 -and $effectiveSiteBPublishedAppBackendTargets[0] -eq $defaultEmptyListSentinel) {
    $effectiveSiteBPublishedAppBackendTargets = @()
  }
  $effectiveSiteAPublishedAppBackendTargets = @(
    $effectiveSiteAPublishedAppBackendTargets |
    ForEach-Object { $_.Trim() } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and $_ -ne $defaultEmptyListSentinel }
  )
  $effectiveSiteBPublishedAppBackendTargets = @(
    $effectiveSiteBPublishedAppBackendTargets |
    ForEach-Object { $_.Trim() } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and $_ -ne $defaultEmptyListSentinel }
  )
  $effectivePublishedAppBackendPort = if ($PublishedAppBackendPort -gt 0) { [double]$PublishedAppBackendPort } else { Get-TfvarsNumberValue -TerraformDirectory $TerraformDir -VariableName "phase4_published_app_backend_port" -DefaultValue 80 }
  $effectivePublishedAppHealthCheckPath = if (-not [string]::IsNullOrWhiteSpace($PublishedAppHealthCheckPath)) { $PublishedAppHealthCheckPath } else { Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "phase4_published_app_health_check_path" -DefaultValue "/healthz" }

  $preflightIssues = New-Object System.Collections.Generic.List[string]

  if (-not $SkipAwsFreeTierChecks) {
    if ($null -eq $aws) {
      $preflightIssues.Add("AWS CLI is required for free-tier preflight checks. Install/configure aws CLI or rerun with -SkipAwsFreeTierChecks.")
    } else {
      $generalTypes = Get-TfvarsStringListValue -TerraformDirectory $TerraformDir -VariableName "phase4_aws_node_instance_types" -DefaultValues @("t3.small")
      $checks = New-Object System.Collections.Generic.List[object]
      $checks.Add((Test-AwsInstanceTypesFreeTierEligible -AwsExecutable $aws -InstanceTypes $generalTypes -Region $siteARegion -Label "phase4_aws_node_instance_types/site-a" -AwsProfileName $AwsProfile))
      $checks.Add((Test-AwsInstanceTypesFreeTierEligible -AwsExecutable $aws -InstanceTypes $generalTypes -Region $siteBRegion -Label "phase4_aws_node_instance_types/site-b" -AwsProfileName $AwsProfile))

      if ($enableAwsVdiWorkers) {
        $vdiTypes = Get-TfvarsStringListValue -TerraformDirectory $TerraformDir -VariableName "phase4_vdi_aws_node_instance_types" -DefaultValues @("t3.small")
        $checks.Add((Test-AwsInstanceTypesFreeTierEligible -AwsExecutable $aws -InstanceTypes $vdiTypes -Region $siteARegion -Label "phase4_vdi_aws_node_instance_types/site-a" -AwsProfileName $AwsProfile))
        $checks.Add((Test-AwsInstanceTypesFreeTierEligible -AwsExecutable $aws -InstanceTypes $vdiTypes -Region $siteBRegion -Label "phase4_vdi_aws_node_instance_types/site-b" -AwsProfileName $AwsProfile))
      } else {
        Write-Host "Skipping AWS VDI free-tier check because phase4_vdi_enable_aws_worker_pools=false."
      }

      foreach ($checkResult in $checks) {
        if (-not $checkResult.ok) {
          $preflightIssues.Add($checkResult.message)
        } else {
          Write-Host $checkResult.message
        }
      }
    }
  } else {
    Write-Warning "Skipping AWS free-tier preflight checks by request."
  }

  if (-not $SkipAwsExistingNodegroupChecks -and $enableAwsVdiWorkers) {
    if ($null -eq $aws) {
      $preflightIssues.Add("AWS CLI is required for existing-nodegroup preflight checks. Install/configure aws CLI or rerun with -SkipAwsExistingNodegroupChecks.")
    } else {
      foreach ($check in $awsChecks) {
        $info = Get-AwsNodegroupInfo -AwsExecutable $aws -ClusterName $check.cluster -NodegroupName $check.nodegroup -Region $check.region -AwsProfileName $AwsProfile
        if ($null -ne $info.error) {
          $preflightIssues.Add("AWS $($check.site): unable to inspect nodegroup '$($check.nodegroup)' in cluster '$($check.cluster)'. Error: $($info.error)")
          continue
        }

        if ($info.exists) {
          if (-not $check.managedInState) {
            $preflightIssues.Add("AWS $($check.site): orphan nodegroup '$($check.nodegroup)' exists but is not tracked in Terraform state. Finish deleting it (or import it) before rerunning.")
            continue
          }

          if ($info.status -in @("CREATING", "DELETING", "UPDATING")) {
            $preflightIssues.Add("AWS $($check.site): nodegroup '$($check.nodegroup)' is currently '$($info.status)'. Wait for a terminal state before rerunning to avoid long blocked applies.")
          }
        } elseif ($check.managedInState) {
          $preflightIssues.Add("AWS $($check.site): Terraform state tracks '$($check.nodegroup)' but AWS does not report it. Reconcile state drift before rerunning.")
        }
      }
    }
  } elseif (-not $enableAwsVdiWorkers) {
    Write-Host "Skipping existing AWS VDI nodegroup checks because phase4_vdi_enable_aws_worker_pools=false."
  } else {
    Write-Warning "Skipping existing AWS nodegroup preflight checks by request."
  }

  if ($EnablePublishedAppPath) {
    if ($null -eq $aws) {
      $preflightIssues.Add("AWS CLI is required for published-app ingress preflight checks. Install/configure aws CLI before enabling -EnablePublishedAppPath.")
    } else {
      try {
        $awsSiteANetwork = Get-TerraformOutputJson -TerraformExecutable $terraform -OutputName "aws_site_a_network"
        $awsSiteBNetwork = Get-TerraformOutputJson -TerraformExecutable $terraform -OutputName "aws_site_b_network"

        $publishedChecks = @(
          [pscustomobject]@{
            site     = "site-a"
            region   = $siteARegion
            vpc_id   = $awsSiteANetwork.vpc_id
            subnets  = @($awsSiteANetwork.ingress_subnets)
            targets  = @($effectiveSiteAPublishedAppBackendTargets)
          },
          [pscustomobject]@{
            site     = "site-b"
            region   = $siteBRegion
            vpc_id   = $awsSiteBNetwork.vpc_id
            subnets  = @($awsSiteBNetwork.ingress_subnets)
            targets  = @($effectiveSiteBPublishedAppBackendTargets)
          }
        )

        Write-Host ("Published app backend preflight: backend_port={0}, health_path={1}" -f $effectivePublishedAppBackendPort, $effectivePublishedAppHealthCheckPath)

        foreach ($publishedCheck in $publishedChecks) {
          $edgeResult = Test-AwsIngressSubnetInternetEdge -AwsExecutable $aws -Site $publishedCheck.site -VpcId $publishedCheck.vpc_id -IngressSubnetIds $publishedCheck.subnets -Region $publishedCheck.region -AwsProfileName $AwsProfile
          if ($edgeResult.ok) {
            Write-Host $edgeResult.message
          } elseif ($ingressInternetEdgeEnabled -eq "true") {
            Write-Warning "$($edgeResult.message) Terraform will create/repair ingress internet edge resources in this apply."
          } else {
            $preflightIssues.Add("$($edgeResult.message) Enable phase4_aws_enable_ingress_internet_edge=true before enabling published app path.")
          }

          if ($publishedCheck.targets.Count -eq 0) {
            Write-Warning "AWS $($publishedCheck.site): no backend target IPs configured. Listener will remain fixed-response (503)."
            continue
          }

          $duplicates = @($publishedCheck.targets | Group-Object | Where-Object { $_.Count -gt 1 } | Select-Object -ExpandProperty Name)
          if ($duplicates.Count -gt 0) {
            $preflightIssues.Add("AWS $($publishedCheck.site): duplicate backend target IPs configured: $($duplicates -join ', ').")
          }

          foreach ($backendTarget in $publishedCheck.targets) {
            if (-not (Test-IsValidIpv4Address -Value $backendTarget)) {
              $preflightIssues.Add("AWS $($publishedCheck.site): backend target '$backendTarget' is not a valid IPv4 address.")
              continue
            }

            $targetCheck = Test-AwsVpcContainsPrivateIp -AwsExecutable $aws -VpcId $publishedCheck.vpc_id -IpAddress $backendTarget -Region $publishedCheck.region -AwsProfileName $AwsProfile
            if ($targetCheck.ok) {
              Write-Host "AWS $($publishedCheck.site): $($targetCheck.message)"
            } else {
              Write-Warning "AWS $($publishedCheck.site): $($targetCheck.message) Ensure target registration and routing are valid for port $effectivePublishedAppBackendPort."
            }
          }
        }
      } catch {
        $preflightIssues.Add("Unable to resolve AWS site network outputs for published-app preflight checks. Error: $($_.Exception.Message)")
      }
    }
  }

  if (-not $SkipGcpQuotaChecks -and $enableGcpVdiWorkers) {
    if ($null -eq $gcloud) {
      $preflightIssues.Add("gcloud CLI is required for GCP quota preflight checks. Install/configure gcloud or rerun with -SkipGcpQuotaChecks.")
    } elseif ([string]::IsNullOrWhiteSpace($gcpProjectIdForPreflight)) {
      $preflightIssues.Add("GCP project ID could not be resolved for quota preflight checks. Pass -GcpProjectId explicitly.")
    } else {
      $gcpVdiMachineType = Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "phase4_vdi_gcp_node_machine_type" -DefaultValue "e2-standard-8"
      $gcpVdiInitialCount = Get-TfvarsNumberValue -TerraformDirectory $TerraformDir -VariableName "phase4_vdi_gcp_node_initial_count" -DefaultValue 1
      $gcpQuotaCheck = Test-GcpVdiCpuQuota -GcloudExecutable $gcloud -ProjectId $gcpProjectIdForPreflight -MachineType $gcpVdiMachineType -InitialNodeCount $gcpVdiInitialCount -GcpClusterChecks $gcpChecks
      if (-not $gcpQuotaCheck.ok) {
        $preflightIssues.Add($gcpQuotaCheck.message)
      } else {
        Write-Host $gcpQuotaCheck.message
      }
    }
  } elseif (-not $enableGcpVdiWorkers) {
    Write-Host "Skipping GCP quota preflight check because phase4_vdi_enable_gcp_worker_pools=false."
  } else {
    Write-Warning "Skipping GCP quota preflight checks by request."
  }

  if ($preflightIssues.Count -gt 0) {
    foreach ($issue in $preflightIssues) {
      Write-Warning $issue
    }

    if ($CollectDiagnosticsOnFailure) {
      Write-VdiFailureDiagnostics -TerraformDirectory $TerraformDir -AwsExecutable $aws -GcloudExecutable $gcloud -AwsProfileName $AwsProfile -Reason "Preflight failed." -AwsChecks $awsChecks -OutputDirectory $DiagnosticsDir
      $diagnosticsWritten = $true
    }

    throw "Preflight checks failed. Fix issues above and rerun."
  }

  Write-Host "Preflight checks passed."
  if ($PreflightOnly) {
    Write-Host "Preflight-only mode: skipping terraform plan/apply."
    return
  }

  Write-Stage -Message "Terraform $command"
  Write-Host "Enabling Phase 4 VDI reference stack."
  Write-Host "Published app path: $publishedEnabled"
  Write-Host "Published app TLS: $publishedTlsEnabled"
  Write-Host "AWS ingress internet edge: $ingressInternetEdgeEnabled"
  if ($EnablePublishedAppPath) {
    Write-Host ("Published app targets site-a: {0}; site-b: {1}; backend_port={2}; health_path={3}" -f $effectiveSiteAPublishedAppBackendTargets.Count, $effectiveSiteBPublishedAppBackendTargets.Count, $effectivePublishedAppBackendPort, $effectivePublishedAppHealthCheckPath)
  }
  Write-Host "Cloudflare edge: $cloudflareEnabled"
  Write-Host "GCP broker identity managed: $((-not $DisableGcpBrokerIdentity).ToString().ToLowerInvariant())"
  if ($DisableAwsWorkerPools) {
    Write-Host "AWS worker pools: disabled by script flag"
  }
  if ($DisableGcpWorkerPools) {
    Write-Host "GCP worker pools: disabled by script flag"
  }
  Invoke-Terraform -Executable $terraform -Arguments $terraformArgs

  if ($PlanOnly -or $SkipHealthChecks) {
    if ($PlanOnly) {
      Write-Host "Plan-only mode: skipping post-plan health checks."
    } else {
      Write-Host "Skipping post-apply health checks by request."
    }
    return
  }

  Write-Stage -Message "Post-Apply Health Checks"
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

  $awsChecks = @()
  if ($null -ne $phase4Vdi.aws.site_a.worker) {
    $awsChecks += [pscustomobject]@{
      site      = "site-a"
      cluster   = $phase4Vdi.aws.site_a.worker.cluster_name
      nodegroup = $phase4Vdi.aws.site_a.worker.node_group_name
      region    = ([regex]::Match($phase3Aws.site_a.cluster_arn, "arn:aws:eks:([^:]+):")).Groups[1].Value
    }
  }
  if ($null -ne $phase4Vdi.aws.site_b.worker) {
    $awsChecks += [pscustomobject]@{
      site      = "site-b"
      cluster   = $phase4Vdi.aws.site_b.worker.cluster_name
      nodegroup = $phase4Vdi.aws.site_b.worker.node_group_name
      region    = ([regex]::Match($phase3Aws.site_b.cluster_arn, "arn:aws:eks:([^:]+):")).Groups[1].Value
    }
  }

  $gcpChecks = @()
  if ($null -ne $phase4Vdi.gcp.site_c.worker) {
    $gcpChecks += [pscustomobject]@{
      site     = "site-c"
      cluster  = $phase4Vdi.gcp.site_c.worker.cluster_name
      nodepool = $phase4Vdi.gcp.site_c.worker.node_pool
      location = $phase4Vdi.gcp.site_c.worker.location
    }
  }
  if ($null -ne $phase4Vdi.gcp.site_d.worker) {
    $gcpChecks += [pscustomobject]@{
      site     = "site-d"
      cluster  = $phase4Vdi.gcp.site_d.worker.cluster_name
      nodepool = $phase4Vdi.gcp.site_d.worker.node_pool
      location = $phase4Vdi.gcp.site_d.worker.location
    }
  }

  if ($awsChecks.Count -eq 0 -and $gcpChecks.Count -eq 0) {
    Write-Host "No VDI worker pools are enabled; skipping worker health checks."
    return
  }

  $unhealthy = New-Object System.Collections.Generic.List[string]

  foreach ($check in $awsChecks) {
    $result = Wait-ForAwsNodegroupActive -AwsExecutable $aws -Check $check -TimeoutMinutes $HealthCheckTimeoutMinutes -PollSeconds $HealthCheckPollSeconds -AwsProfileName $AwsProfile
    if (-not $result.healthy) {
      $unhealthy.Add($result.message)
    }
  }

  foreach ($check in $gcpChecks) {
    $result = Wait-ForGcpNodepoolRunning -GcloudExecutable $gcloud -Check $check -ProjectId $projectId -TimeoutMinutes $HealthCheckTimeoutMinutes -PollSeconds $HealthCheckPollSeconds
    if (-not $result.healthy) {
      $unhealthy.Add($result.message)
    }
  }

  if ($unhealthy.Count -gt 0) {
    foreach ($msg in $unhealthy) {
      Write-Warning $msg
    }

    if ($CollectDiagnosticsOnFailure) {
      Write-VdiFailureDiagnostics -TerraformDirectory $TerraformDir -AwsExecutable $aws -GcloudExecutable $gcloud -AwsProfileName $AwsProfile -ProjectId $projectId -AwsChecks $awsChecks -GcpChecks $gcpChecks -Reason "Post-apply health checks reported unhealthy workers." -OutputDirectory $DiagnosticsDir
      $diagnosticsWritten = $true
    }

    if ($FailOnUnhealthy) {
      throw "One or more VDI worker health checks failed."
    }
  } else {
    Write-Host "Phase 4 VDI worker health checks passed."
  }
} catch {
  if ($CollectDiagnosticsOnFailure -and -not $diagnosticsWritten) {
    try {
      Write-VdiFailureDiagnostics -TerraformDirectory $TerraformDir -AwsExecutable $aws -GcloudExecutable $gcloud -AwsProfileName $AwsProfile -ProjectId $projectId -AwsChecks $awsChecks -GcpChecks $gcpChecks -Reason "Script execution failed: $($_.Exception.Message)" -OutputDirectory $DiagnosticsDir
    } catch {
      Write-Warning "Failed to collect diagnostics after error: $($_.Exception.Message)"
    }
  }

  throw
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
