param(
  [string]$TerraformDir = "",
  [string]$AwsProfile = "",
  [string]$SiteARegion = "",
  [string]$SiteBRegion = "",
  [string]$PostgresSourceImage = "postgres:16-alpine",
  [string]$GuacdSourceImage = "guacamole/guacd:1.5.5",
  [string]$GuacamoleSourceImage = "guacamole/guacamole:1.5.5",
  [string]$NginxSourceImage = "nginx:1.27-alpine",
  [string]$DesktopSourceImage = "dorowu/ubuntu-desktop-lxde-vnc:latest",
  [string]$EcrPostgresRepositoryName = "ddc-vdi-postgres",
  [string]$EcrGuacdRepositoryName = "ddc-vdi-guacd",
  [string]$EcrGuacamoleRepositoryName = "ddc-vdi-guacamole",
  [string]$EcrNginxRepositoryName = "ddc-vdi-nginx",
  [string]$EcrDesktopRepositoryName = "ddc-vdi-desktop",
  [switch]$MirrorDesktopImage,
  [switch]$SkipSourcePull
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

function Invoke-CommandChecked {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Executable,
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments,
    [string]$Label = ""
  )

  $labelPrefix = if ([string]::IsNullOrWhiteSpace($Label)) { "" } else { "[$Label] " }
  Write-Host "$labelPrefix$Executable $($Arguments -join ' ')"
  & $Executable @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed (exit $LASTEXITCODE): $Executable $($Arguments -join ' ')"
  }
}

function Invoke-CommandCapture {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Executable,
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments,
    [string]$Label = ""
  )

  $labelPrefix = if ([string]::IsNullOrWhiteSpace($Label)) { "" } else { "[$Label] " }
  Write-Host "$labelPrefix$Executable $($Arguments -join ' ')"
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

function Get-ImageTag {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Image
  )

  if ($Image -match ":(?<tag>[^/:@]+)$") {
    return $Matches["tag"]
  }

  return "latest"
}

function Ensure-EcrRepository {
  param(
    [Parameter(Mandatory = $true)]
    [string]$AwsExecutable,
    [Parameter(Mandatory = $true)]
    [string]$Region,
    [Parameter(Mandatory = $true)]
    [string]$RepositoryName
  )

  $describe = Invoke-CommandCapture -Executable $AwsExecutable -Arguments @("ecr", "describe-repositories", "--region", $Region, "--repository-names", $RepositoryName) -Label "ecr-describe-$Region-$RepositoryName"
  if ($describe.exit_code -eq 0) {
    return
  }

  if ($describe.output -notmatch "RepositoryNotFoundException") {
    throw "Unable to inspect ECR repository '$RepositoryName' in region '$Region'. Error: $($describe.output)"
  }

  Invoke-CommandChecked -Executable $AwsExecutable -Arguments @("ecr", "create-repository", "--region", $Region, "--repository-name", $RepositoryName) -Label "ecr-create-$Region-$RepositoryName"
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

$aws = Get-ToolPath -Name "aws"
if ($null -eq $aws) {
  throw "aws CLI not found in PATH."
}

$docker = Get-ToolPath -Name "docker"
if ($null -eq $docker) {
  throw "docker not found in PATH."
}

if ([string]::IsNullOrWhiteSpace($SiteARegion)) {
  $SiteARegion = Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "aws_site_a_region" -DefaultValue "us-east-1"
}
if ([string]::IsNullOrWhiteSpace($SiteBRegion)) {
  $SiteBRegion = Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "aws_site_b_region" -DefaultValue "us-west-2"
}

$regions = @($SiteARegion, $SiteBRegion | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
if ($regions.Count -eq 0) {
  throw "No target regions resolved."
}

if (-not $SkipSourcePull) {
  Invoke-CommandChecked -Executable $docker -Arguments @("pull", $PostgresSourceImage) -Label "docker-pull-postgres"
  Invoke-CommandChecked -Executable $docker -Arguments @("pull", $GuacdSourceImage) -Label "docker-pull-guacd"
  Invoke-CommandChecked -Executable $docker -Arguments @("pull", $GuacamoleSourceImage) -Label "docker-pull-guacamole"
  Invoke-CommandChecked -Executable $docker -Arguments @("pull", $NginxSourceImage) -Label "docker-pull-nginx"
  if ($MirrorDesktopImage) {
    Invoke-CommandChecked -Executable $docker -Arguments @("pull", $DesktopSourceImage) -Label "docker-pull-desktop"
  }
}

$accountResult = Invoke-CommandCapture -Executable $aws -Arguments @("sts", "get-caller-identity", "--query", "Account", "--output", "text") -Label "aws-account"
if ($accountResult.exit_code -ne 0 -or [string]::IsNullOrWhiteSpace($accountResult.output)) {
  throw "Unable to resolve AWS account ID. Error: $($accountResult.output)"
}
$accountId = $accountResult.output.Trim()

$postgresTag = Get-ImageTag -Image $PostgresSourceImage
$guacdTag = Get-ImageTag -Image $GuacdSourceImage
$guacamoleTag = Get-ImageTag -Image $GuacamoleSourceImage
$nginxTag = Get-ImageTag -Image $NginxSourceImage
$desktopTag = Get-ImageTag -Image $DesktopSourceImage

$mirrored = New-Object System.Collections.Generic.List[object]
foreach ($region in $regions) {
  Write-Host ""
  Write-Host "== Mirroring images to ECR region $region =="

  Ensure-EcrRepository -AwsExecutable $aws -Region $region -RepositoryName $EcrPostgresRepositoryName
  Ensure-EcrRepository -AwsExecutable $aws -Region $region -RepositoryName $EcrGuacdRepositoryName
  Ensure-EcrRepository -AwsExecutable $aws -Region $region -RepositoryName $EcrGuacamoleRepositoryName
  Ensure-EcrRepository -AwsExecutable $aws -Region $region -RepositoryName $EcrNginxRepositoryName
  if ($MirrorDesktopImage) {
    Ensure-EcrRepository -AwsExecutable $aws -Region $region -RepositoryName $EcrDesktopRepositoryName
  }

  $registry = "$accountId.dkr.ecr.$region.amazonaws.com"
  $passwordResult = Invoke-CommandCapture -Executable $aws -Arguments @("ecr", "get-login-password", "--region", $region) -Label "ecr-login-token-$region"
  if ($passwordResult.exit_code -ne 0 -or [string]::IsNullOrWhiteSpace($passwordResult.output)) {
    throw "Unable to get ECR login password for region '$region'. Error: $($passwordResult.output)"
  }

  $password = $passwordResult.output.Trim()
  $password | & $docker login --username AWS --password-stdin $registry | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "docker login failed for registry '$registry'."
  }

  $targetPostgres = "$registry/${EcrPostgresRepositoryName}:$postgresTag"
  $targetGuacd = "$registry/${EcrGuacdRepositoryName}:$guacdTag"
  $targetGuacamole = "$registry/${EcrGuacamoleRepositoryName}:$guacamoleTag"
  $targetNginx = "$registry/${EcrNginxRepositoryName}:$nginxTag"
  $targetDesktop = "$registry/${EcrDesktopRepositoryName}:$desktopTag"

  Invoke-CommandChecked -Executable $docker -Arguments @("tag", $PostgresSourceImage, $targetPostgres) -Label "docker-tag-postgres-$region"
  Invoke-CommandChecked -Executable $docker -Arguments @("tag", $GuacdSourceImage, $targetGuacd) -Label "docker-tag-guacd-$region"
  Invoke-CommandChecked -Executable $docker -Arguments @("tag", $GuacamoleSourceImage, $targetGuacamole) -Label "docker-tag-guacamole-$region"
  Invoke-CommandChecked -Executable $docker -Arguments @("tag", $NginxSourceImage, $targetNginx) -Label "docker-tag-nginx-$region"
  if ($MirrorDesktopImage) {
    Invoke-CommandChecked -Executable $docker -Arguments @("tag", $DesktopSourceImage, $targetDesktop) -Label "docker-tag-desktop-$region"
  }
  Invoke-CommandChecked -Executable $docker -Arguments @("push", $targetPostgres) -Label "docker-push-postgres-$region"
  Invoke-CommandChecked -Executable $docker -Arguments @("push", $targetGuacd) -Label "docker-push-guacd-$region"
  Invoke-CommandChecked -Executable $docker -Arguments @("push", $targetGuacamole) -Label "docker-push-guacamole-$region"
  Invoke-CommandChecked -Executable $docker -Arguments @("push", $targetNginx) -Label "docker-push-nginx-$region"
  if ($MirrorDesktopImage) {
    Invoke-CommandChecked -Executable $docker -Arguments @("push", $targetDesktop) -Label "docker-push-desktop-$region"
  }

  $entry = [ordered]@{
    region          = $region
    postgres_image  = $targetPostgres
    guacd_image     = $targetGuacd
    guacamole_image = $targetGuacamole
    nginx_image     = $targetNginx
  }
  if ($MirrorDesktopImage) {
    $entry.desktop_image = $targetDesktop
  }

  $mirrored.Add([pscustomobject]$entry)
}

$mirroredArray = $mirrored.ToArray()
Write-Host ""
Write-Host "Mirrored images:"
$mirroredArray | ConvertTo-Json -Depth 5 | Write-Host

Write-Host ""
Write-Host "Next command:"
Write-Host ".\scripts\invoke_phase4_vdi_service_bootstrap.ps1 -AwsProfile `"$AwsProfile`" -UseRegionalEcrImages -EcrAccountId `"$accountId`""
if ($MirrorDesktopImage) {
  Write-Host ".\scripts\invoke_phase4_vdi_service_bootstrap.ps1 -AwsProfile `"$AwsProfile`" -UseRegionalEcrImages -UseRegionalEcrDesktopImage -EnableSampleVdiDesktop -EcrAccountId `"$accountId`""
}
