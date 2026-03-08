param(
  [string]$ProjectId = "worldbuilder-413006",
  [string[]]$AwsRegions = @("us-east-1", "us-west-2"),
  [string]$AwsProfile = "",
  [string]$TerraformDir = "",
  [string]$OutputRoot = "",
  [switch]$SkipTerraform,
  [switch]$SkipAws,
  [switch]$SkipGcp,
  [switch]$SkipPublishedAppChecks,
  [switch]$SkipCloudflareDnsChecks,
  [string]$DnsResolver = "1.1.1.1",
  [switch]$FailOnCommandError
)

$ErrorActionPreference = "Stop"
$script:CommandErrors = New-Object System.Collections.Generic.List[string]

if ([string]::IsNullOrWhiteSpace($TerraformDir)) {
  $TerraformDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path $TerraformDir "evidence"
}

if ([string]::IsNullOrWhiteSpace($AwsProfile)) {
  $AwsProfile = $env:AWS_PROFILE
}

function Resolve-ToolPath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$CommandName
  )

  $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
  if ($null -eq $cmd) {
    return $null
  }

  return $cmd.Source
}

function Save-Json {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    $Object
  )

  $Object | ConvertTo-Json -Depth 100 | Set-Content -Path $Path
}

function Invoke-CapturedCommand {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Executable,
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments,
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,
    [Parameter(Mandatory = $true)]
    [string]$Label
  )

  Write-Host "[$Label] $Executable $($Arguments -join ' ')"
  $output = & $Executable @Arguments 2>&1
  $exitCode = $LASTEXITCODE
  $outputText = if ($null -eq $output) { "" } else { ($output | Out-String) }
  Set-Content -Path $OutputPath -Value $outputText

  if ($exitCode -ne 0) {
    $script:CommandErrors.Add("Command failed ($Label): exit code $exitCode")
  }

  return [pscustomobject]@{
    ExitCode = $exitCode
    Output   = $outputText
    File     = $OutputPath
  }
}

function Try-ParseJson {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Text
  )

  try {
    return ($Text | ConvertFrom-Json)
  } catch {
    return $null
  }
}

function Invoke-HttpProbe {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Uri,
    [int]$TimeoutSec = 15
  )

  try {
    $response = Invoke-WebRequest -Uri $Uri -Method Get -TimeoutSec $TimeoutSec -MaximumRedirection 0 -ErrorAction Stop
    return [pscustomobject]@{
      ok          = $true
      status_code = [int]$response.StatusCode
      error       = $null
    }
  } catch {
    $statusCode = $null
    if ($null -ne $_.Exception.Response -and $null -ne $_.Exception.Response.StatusCode) {
      $statusCode = [int]$_.Exception.Response.StatusCode
      return [pscustomobject]@{
        ok          = $true
        status_code = $statusCode
        error       = $_.Exception.Message
      }
    }

    return [pscustomobject]@{
      ok          = $false
      status_code = $null
      error       = $_.Exception.Message
    }
  }
}

function Resolve-CloudflareDnsState {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Hostname,
    [Parameter(Mandatory = $true)]
    [string]$Target,
    [Parameter(Mandatory = $true)]
    [bool]$Proxied,
    [string]$Resolver = "1.1.1.1"
  )

  $resolved = $false
  $targetMatch = $false
  $cnameTarget = $null
  $addresses = @()
  $errorMessages = New-Object System.Collections.Generic.List[string]

  try {
    $cnameResult = Resolve-DnsName -Name $Hostname -Type CNAME -Server $Resolver -ErrorAction Stop
    $firstCname = $cnameResult | Select-Object -First 1
    if ($null -ne $firstCname -and -not [string]::IsNullOrWhiteSpace($firstCname.NameHost)) {
      $cnameTarget = $firstCname.NameHost.TrimEnd(".")
      $resolved = $true
    }
  } catch {
    $errorMessages.Add($_.Exception.Message)
  }

  if (-not $resolved) {
    try {
      $aResult = Resolve-DnsName -Name $Hostname -Type A -Server $Resolver -ErrorAction Stop
      $addresses = @($aResult | Where-Object { -not [string]::IsNullOrWhiteSpace($_.IPAddress) } | Select-Object -ExpandProperty IPAddress)
      if ($addresses.Count -gt 0) {
        $resolved = $true
      }
    } catch {
      $errorMessages.Add($_.Exception.Message)
    }
  }

  if (-not [string]::IsNullOrWhiteSpace($cnameTarget)) {
    $targetMatch = $cnameTarget.ToLowerInvariant() -eq $Target.TrimEnd(".").ToLowerInvariant()
  } elseif ($Proxied -and $resolved) {
    # Proxied records can hide origin target behind Cloudflare A/AAAA responses.
    $targetMatch = $true
  }

  return [pscustomobject]@{
    hostname     = $Hostname
    target       = $Target
    proxied      = $Proxied
    resolver     = $Resolver
    resolved     = $resolved
    target_match = $targetMatch
    cname_target = $cnameTarget
    addresses    = @($addresses)
    error        = ($errorMessages.ToArray() -join " | ")
  }
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$runDir = Join-Path $OutputRoot ("phase5-" + $timestamp)
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

$summary = [ordered]@{
  generated_utc = (Get-Date).ToUniversalTime().ToString("o")
  run_directory = $runDir
  inputs        = [ordered]@{
    project_id    = $ProjectId
    aws_regions   = $AwsRegions
    aws_profile   = $AwsProfile
    terraform_dir = $TerraformDir
  }
  checks        = [ordered]@{}
  metrics       = [ordered]@{
    aws_vpn_connections_total   = 0
    aws_vpn_connections_up       = 0
    gcp_vpn_tunnels_total        = 0
    gcp_vpn_tunnels_established  = 0
    eks_clusters_total           = 0
    eks_clusters_active          = 0
    gke_clusters_total           = 0
    gke_clusters_running         = 0
    published_app_endpoints_total   = 0
    published_app_endpoints_healthy = 0
    cloudflare_records_total        = 0
    cloudflare_records_resolving    = 0
    cloudflare_records_target_match = 0
  }
  errors        = @()
}

$awsVpnStates = @()
$gcpVpnStates = @()
$eksClusterStates = @()
$gkeClusterStates = @()
$publishedAppEndpointStates = @()
$cloudflareDnsStates = @()
$phase4PublishedAppPaths = $null
$phase4CloudflareRecords = $null

if (-not $SkipTerraform) {
  $terraform = Resolve-ToolPath -CommandName "terraform"
  if ($null -eq $terraform) {
    $script:CommandErrors.Add("terraform not found in PATH")
    $summary.checks.terraform = "missing"
  } else {
    $tfDir = Join-Path $runDir "terraform"
    New-Item -ItemType Directory -Path $tfDir -Force | Out-Null

    Push-Location $TerraformDir
    try {
      $tfVersion = Invoke-CapturedCommand -Executable $terraform -Arguments @("version") -OutputPath (Join-Path $tfDir "terraform_version.txt") -Label "terraform-version"
      $tfOutputs = Invoke-CapturedCommand -Executable $terraform -Arguments @("output", "-json") -OutputPath (Join-Path $tfDir "terraform_outputs.json") -Label "terraform-output"
      $tfState = Invoke-CapturedCommand -Executable $terraform -Arguments @("state", "list") -OutputPath (Join-Path $tfDir "terraform_state_list.txt") -Label "terraform-state-list"

      if ($tfOutputs.ExitCode -eq 0) {
        $tfOutputsJson = Try-ParseJson -Text $tfOutputs.Output
        if ($null -ne $tfOutputsJson) {
          if ($null -ne $tfOutputsJson.phase4_published_app_paths) {
            $phase4PublishedAppPaths = $tfOutputsJson.phase4_published_app_paths.value
          }
          if ($null -ne $tfOutputsJson.phase4_cloudflare_edge_records) {
            $phase4CloudflareRecords = $tfOutputsJson.phase4_cloudflare_edge_records.value
          }
        }
      }

      $summary.checks.terraform = [ordered]@{
        version_exit_code = $tfVersion.ExitCode
        output_exit_code  = $tfOutputs.ExitCode
        state_exit_code   = $tfState.ExitCode
      }
    } finally {
      Pop-Location
    }
  }
} else {
  $summary.checks.terraform = "skipped"
}

if (-not $SkipAws) {
  $aws = Resolve-ToolPath -CommandName "aws"
  if ($null -eq $aws) {
    $script:CommandErrors.Add("aws CLI not found in PATH")
    $summary.checks.aws = "missing"
  } else {
    $awsDir = Join-Path $runDir "aws"
    New-Item -ItemType Directory -Path $awsDir -Force | Out-Null
    $awsBaseArgs = @()
    if (-not [string]::IsNullOrWhiteSpace($AwsProfile)) {
      $awsBaseArgs += @("--profile", $AwsProfile)
    }

    foreach ($region in $AwsRegions) {
      $regionDir = Join-Path $awsDir $region
      New-Item -ItemType Directory -Path $regionDir -Force | Out-Null

      $vpnCapture = Invoke-CapturedCommand -Executable $aws -Arguments ($awsBaseArgs + @("ec2", "describe-vpn-connections", "--region", $region, "--output", "json")) -OutputPath (Join-Path $regionDir "vpn_connections.json") -Label ("aws-vpn-" + $region)
      $vpnJson = Try-ParseJson -Text $vpnCapture.Output
      if ($null -ne $vpnJson -and $null -ne $vpnJson.VpnConnections) {
        foreach ($vpn in $vpnJson.VpnConnections) {
          $awsVpnStates += [pscustomobject]@{
            region = $region
            id     = $vpn.VpnConnectionId
            state  = $vpn.State
          }
        }
      }

      $clustersCapture = Invoke-CapturedCommand -Executable $aws -Arguments ($awsBaseArgs + @("eks", "list-clusters", "--region", $region, "--output", "json")) -OutputPath (Join-Path $regionDir "eks_clusters.json") -Label ("aws-eks-list-" + $region)
      $clustersJson = Try-ParseJson -Text $clustersCapture.Output
      $clusterNames = @()
      if ($null -ne $clustersJson -and $null -ne $clustersJson.clusters) {
        $clusterNames = @($clustersJson.clusters)
      }

      foreach ($clusterName in $clusterNames) {
        $safeClusterName = ($clusterName -replace "[^A-Za-z0-9_.-]", "_")
        $clusterDir = Join-Path $regionDir ("cluster-" + $safeClusterName)
        New-Item -ItemType Directory -Path $clusterDir -Force | Out-Null

        $clusterCapture = Invoke-CapturedCommand -Executable $aws -Arguments ($awsBaseArgs + @("eks", "describe-cluster", "--region", $region, "--name", $clusterName, "--output", "json")) -OutputPath (Join-Path $clusterDir "cluster.json") -Label ("aws-eks-describe-" + $clusterName)
        $clusterJson = Try-ParseJson -Text $clusterCapture.Output
        if ($null -ne $clusterJson -and $null -ne $clusterJson.cluster) {
          $eksClusterStates += [pscustomobject]@{
            region = $region
            name   = $clusterName
            status = $clusterJson.cluster.status
          }
        }

        $nodegroupsCapture = Invoke-CapturedCommand -Executable $aws -Arguments ($awsBaseArgs + @("eks", "list-nodegroups", "--region", $region, "--cluster-name", $clusterName, "--output", "json")) -OutputPath (Join-Path $clusterDir "nodegroups.json") -Label ("aws-eks-nodegroups-" + $clusterName)
        $nodegroupsJson = Try-ParseJson -Text $nodegroupsCapture.Output
        $nodeGroupNames = @()
        if ($null -ne $nodegroupsJson -and $null -ne $nodegroupsJson.nodegroups) {
          $nodeGroupNames = @($nodegroupsJson.nodegroups)
        }

        foreach ($nodeGroup in $nodeGroupNames) {
          $safeNodeGroup = ($nodeGroup -replace "[^A-Za-z0-9_.-]", "_")
          Invoke-CapturedCommand -Executable $aws -Arguments ($awsBaseArgs + @("eks", "describe-nodegroup", "--region", $region, "--cluster-name", $clusterName, "--nodegroup-name", $nodeGroup, "--output", "json")) -OutputPath (Join-Path $clusterDir ("nodegroup-" + $safeNodeGroup + ".json")) -Label ("aws-eks-nodegroup-" + $nodeGroup) | Out-Null
        }
      }
    }

    $summary.checks.aws = "captured"
  }
} else {
  $summary.checks.aws = "skipped"
}

if (-not $SkipGcp) {
  $gcloud = Resolve-ToolPath -CommandName "gcloud"
  if ($null -eq $gcloud) {
    $script:CommandErrors.Add("gcloud not found in PATH")
    $summary.checks.gcp = "missing"
  } else {
    $gcpDir = Join-Path $runDir "gcp"
    New-Item -ItemType Directory -Path $gcpDir -Force | Out-Null

    Invoke-CapturedCommand -Executable $gcloud -Arguments @("version") -OutputPath (Join-Path $gcpDir "gcloud_version.txt") -Label "gcloud-version" | Out-Null

    $vpnCapture = Invoke-CapturedCommand -Executable $gcloud -Arguments @("compute", "vpn-tunnels", "list", "--project", $ProjectId, "--format", "json") -OutputPath (Join-Path $gcpDir "vpn_tunnels.json") -Label "gcp-vpn-tunnels"
    $vpnJson = Try-ParseJson -Text $vpnCapture.Output
    if ($null -ne $vpnJson) {
      foreach ($tunnel in @($vpnJson)) {
        $gcpVpnStates += [pscustomobject]@{
          name   = $tunnel.name
          region = $tunnel.region
          status = $tunnel.status
        }
      }
    }

    $routersCapture = Invoke-CapturedCommand -Executable $gcloud -Arguments @("compute", "routers", "list", "--project", $ProjectId, "--format", "json") -OutputPath (Join-Path $gcpDir "routers.json") -Label "gcp-routers"
    $routersJson = Try-ParseJson -Text $routersCapture.Output
    if ($null -ne $routersJson) {
      foreach ($router in @($routersJson)) {
        $region = ""
        if ($router.region -match "/regions/([^/]+)$") {
          $region = $Matches[1]
        }
        if (-not [string]::IsNullOrWhiteSpace($region)) {
          $safeRouter = ($router.name -replace "[^A-Za-z0-9_.-]", "_")
          Invoke-CapturedCommand -Executable $gcloud -Arguments @("compute", "routers", "get-status", $router.name, "--region", $region, "--project", $ProjectId, "--format", "json") -OutputPath (Join-Path $gcpDir ("router-status-" + $safeRouter + ".json")) -Label ("gcp-router-status-" + $router.name) | Out-Null
        }
      }
    }

    $clustersCapture = Invoke-CapturedCommand -Executable $gcloud -Arguments @("container", "clusters", "list", "--project", $ProjectId, "--format", "json") -OutputPath (Join-Path $gcpDir "gke_clusters.json") -Label "gcp-gke-clusters"
    $clustersJson = Try-ParseJson -Text $clustersCapture.Output
    if ($null -ne $clustersJson) {
      foreach ($cluster in @($clustersJson)) {
        $gkeClusterStates += [pscustomobject]@{
          name     = $cluster.name
          location = $cluster.location
          status   = $cluster.status
        }

        $safeCluster = ($cluster.name -replace "[^A-Za-z0-9_.-]", "_")
        $clusterDir = Join-Path $gcpDir ("cluster-" + $safeCluster)
        New-Item -ItemType Directory -Path $clusterDir -Force | Out-Null

        Invoke-CapturedCommand -Executable $gcloud -Arguments @("container", "clusters", "describe", $cluster.name, "--location", $cluster.location, "--project", $ProjectId, "--format", "json") -OutputPath (Join-Path $clusterDir "cluster.json") -Label ("gcp-gke-describe-" + $cluster.name) | Out-Null
        Invoke-CapturedCommand -Executable $gcloud -Arguments @("container", "node-pools", "list", "--cluster", $cluster.name, "--location", $cluster.location, "--project", $ProjectId, "--format", "json") -OutputPath (Join-Path $clusterDir "node_pools.json") -Label ("gcp-gke-nodepools-" + $cluster.name) | Out-Null
      }
    }

    $summary.checks.gcp = "captured"
  }
} else {
  $summary.checks.gcp = "skipped"
}

if (-not $SkipPublishedAppChecks) {
  if ($null -eq $phase4PublishedAppPaths -or @($phase4PublishedAppPaths.PSObject.Properties).Count -eq 0) {
    $summary.checks.published_app = "not-configured"
  } else {
    foreach ($siteProperty in $phase4PublishedAppPaths.PSObject.Properties) {
      $site = $siteProperty.Name
      $siteSummary = $siteProperty.Value
      if ($null -eq $siteSummary -or [string]::IsNullOrWhiteSpace($siteSummary.load_balancer_dns)) {
        continue
      }

      $healthPath = if ([string]::IsNullOrWhiteSpace($siteSummary.health_check_path)) { "/" } else { $siteSummary.health_check_path }
      $probeUri = "http://$($siteSummary.load_balancer_dns)$healthPath"
      $probe = Invoke-HttpProbe -Uri $probeUri
      $trafficMode = "$($siteSummary.traffic_mode)"
      $isHealthy = $false
      $expected = ""
      if ($trafficMode -eq "fixed-response") {
        $expected = "503"
        $isHealthy = $probe.ok -and $probe.status_code -eq 503
      } else {
        $expected = "2xx-4xx"
        $isHealthy = $probe.ok -and $probe.status_code -ge 200 -and $probe.status_code -lt 500
      }

      $publishedAppEndpointStates += [pscustomobject]@{
        site         = $site
        uri          = $probeUri
        traffic_mode = $trafficMode
        expected     = $expected
        status_code  = $probe.status_code
        healthy      = $isHealthy
        error        = $probe.error
      }
    }

    $summary.checks.published_app = "captured"
  }
} else {
  $summary.checks.published_app = "skipped"
}

if (-not $SkipCloudflareDnsChecks) {
  if ($null -eq $phase4CloudflareRecords -or @($phase4CloudflareRecords.PSObject.Properties).Count -eq 0) {
    $summary.checks.cloudflare_dns = "not-configured"
  } else {
    foreach ($recordProperty in $phase4CloudflareRecords.PSObject.Properties) {
      $site = $recordProperty.Name
      $record = $recordProperty.Value
      if ($null -eq $record -or [string]::IsNullOrWhiteSpace($record.hostname) -or [string]::IsNullOrWhiteSpace($record.target)) {
        continue
      }

      $dnsState = Resolve-CloudflareDnsState -Hostname $record.hostname -Target $record.target -Proxied ([bool]$record.proxied) -Resolver $DnsResolver
      $cloudflareDnsStates += [pscustomobject]@{
        site         = $site
        hostname     = $dnsState.hostname
        target       = $dnsState.target
        proxied      = $dnsState.proxied
        resolver     = $dnsState.resolver
        resolved     = $dnsState.resolved
        target_match = $dnsState.target_match
        cname_target = $dnsState.cname_target
        addresses    = @($dnsState.addresses)
        error        = $dnsState.error
      }
    }

    $summary.checks.cloudflare_dns = "captured"
  }
} else {
  $summary.checks.cloudflare_dns = "skipped"
}

$summary.metrics.aws_vpn_connections_total = @($awsVpnStates).Count
$summary.metrics.aws_vpn_connections_up = (@($awsVpnStates | Where-Object { $_.state -eq "available" })).Count
$summary.metrics.gcp_vpn_tunnels_total = @($gcpVpnStates).Count
$summary.metrics.gcp_vpn_tunnels_established = (@($gcpVpnStates | Where-Object { $_.status -eq "ESTABLISHED" })).Count
$summary.metrics.eks_clusters_total = @($eksClusterStates).Count
$summary.metrics.eks_clusters_active = (@($eksClusterStates | Where-Object { $_.status -eq "ACTIVE" })).Count
$summary.metrics.gke_clusters_total = @($gkeClusterStates).Count
$summary.metrics.gke_clusters_running = (@($gkeClusterStates | Where-Object { $_.status -eq "RUNNING" })).Count
$summary.metrics.published_app_endpoints_total = @($publishedAppEndpointStates).Count
$summary.metrics.published_app_endpoints_healthy = (@($publishedAppEndpointStates | Where-Object { $_.healthy })).Count
$summary.metrics.cloudflare_records_total = @($cloudflareDnsStates).Count
$summary.metrics.cloudflare_records_resolving = (@($cloudflareDnsStates | Where-Object { $_.resolved })).Count
$summary.metrics.cloudflare_records_target_match = (@($cloudflareDnsStates | Where-Object { $_.target_match })).Count
$summary.errors = @($script:CommandErrors)

Save-Json -Path (Join-Path $runDir "phase5_summary.json") -Object $summary
Save-Json -Path (Join-Path $runDir "aws_vpn_states.json") -Object $awsVpnStates
Save-Json -Path (Join-Path $runDir "gcp_vpn_states.json") -Object $gcpVpnStates
Save-Json -Path (Join-Path $runDir "eks_cluster_states.json") -Object $eksClusterStates
Save-Json -Path (Join-Path $runDir "gke_cluster_states.json") -Object $gkeClusterStates
Save-Json -Path (Join-Path $runDir "published_app_endpoint_states.json") -Object $publishedAppEndpointStates
Save-Json -Path (Join-Path $runDir "cloudflare_dns_states.json") -Object $cloudflareDnsStates

$summaryMarkdown = @"
# Phase 5 Evidence Summary

- Generated (UTC): $($summary.generated_utc)
- Output directory: $($summary.run_directory)

## Health Snapshot

| Check | Healthy | Total |
|---|---:|---:|
| AWS VPN connections (available) | $($summary.metrics.aws_vpn_connections_up) | $($summary.metrics.aws_vpn_connections_total) |
| GCP VPN tunnels (`ESTABLISHED`) | $($summary.metrics.gcp_vpn_tunnels_established) | $($summary.metrics.gcp_vpn_tunnels_total) |
| EKS clusters (`ACTIVE`) | $($summary.metrics.eks_clusters_active) | $($summary.metrics.eks_clusters_total) |
| GKE clusters (`RUNNING`) | $($summary.metrics.gke_clusters_running) | $($summary.metrics.gke_clusters_total) |
| Published app endpoints (expected status) | $($summary.metrics.published_app_endpoints_healthy) | $($summary.metrics.published_app_endpoints_total) |
| Cloudflare DNS records (resolving) | $($summary.metrics.cloudflare_records_resolving) | $($summary.metrics.cloudflare_records_total) |
| Cloudflare DNS records (target match) | $($summary.metrics.cloudflare_records_target_match) | $($summary.metrics.cloudflare_records_total) |

## Deliverable Mapping (Phase 5)

- Execute failover scenarios and DR runbooks: see `execution_record.md` and captured command outputs.
- Backup and restore drills against RTO/RPO: add drill timestamps and links in `execution_record.md`.
- Operations handover sign-off: complete sign-off section in `execution_record.md`.
"@

Set-Content -Path (Join-Path $runDir "phase5_summary.md") -Value $summaryMarkdown

$executionRecordTemplate = @"
# Phase 5 Execution Record

## Run Metadata
- Run ID: `phase5-$timestamp`
- Date (UTC):
- Coordinator:
- Change ticket:

## Scenario Results
| Scenario | Target RTO | Target RPO | Start (UTC) | Recovery (UTC) | Measured RTO | Measured RPO | Result | Evidence Link |
|---|---|---|---|---|---|---|---|---|
| A) Single Compute Node Failure | 5-15 min | 0-5 min |  |  |  |  |  |  |
| B) ToR Switch Failure | 10-20 min | 0 min |  |  |  |  |  |  |
| C) Edge Firewall/Router Failure | 5-15 min | 0-5 min |  |  |  |  |  |  |
| D) WAN Circuit Failure | 15-30 min | 5-15 min |  |  |  |  |  |  |
| E) Full Site Outage | 60-120 min (Tier 1) | up to 15 min (Tier 1) |  |  |  |  |  |  |
| F) Data Corruption Event | within 4h (Tier 1) | last clean point |  |  |  |  |  |  |

## Backup and Restore Drill
- Dataset/service:
- Restore point timestamp:
- Restore start (UTC):
- Restore completion (UTC):
- Validation outcome:
- Evidence links:

## Handover Sign-Off
- Network/Security lead:
- Platform lead:
- Operations lead:
- Governance lead:
- Sign-off date:
- Residual risks:
"@

Set-Content -Path (Join-Path $runDir "execution_record.md") -Value $executionRecordTemplate
Set-Content -Path (Join-Path $OutputRoot "phase5-latest.txt") -Value $runDir

if ($summary.errors.Count -gt 0) {
  Write-Warning ("Evidence capture completed with {0} command error(s)." -f $summary.errors.Count)
  foreach ($err in $summary.errors) {
    Write-Warning $err
  }
} else {
  Write-Host "Evidence capture completed without command errors."
}

Write-Host "Artifacts written to: $runDir"

if ($FailOnCommandError -and $summary.errors.Count -gt 0) {
  exit 1
}
