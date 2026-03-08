param(
  [string]$TerraformDir = "",
  [string]$AwsProfile = "",
  [string]$ManifestPath = "",
  [string]$DbInitSqlPath = "",
  [string]$DesktopManifestPath = "",
  [string]$GuacdImage = "guacamole/guacd:1.5.5",
  [string]$GuacamoleImage = "guacamole/guacamole:1.5.5",
  [string]$PostgresImage = "postgres:16-alpine",
  [string]$NginxImage = "nginx:1.27-alpine",
  [string]$GuacamoleDbName = "",
  [string]$GuacamoleDbUser = "",
  [string]$GuacamoleDbPassword = "",
  [string]$DesktopImage = "dorowu/ubuntu-desktop-lxde-vnc:latest",
  [string]$DesktopConnectionName = "VDI Desktop",
  [int]$DesktopVncPort = 5900,
  [string]$DesktopVncPassword = "",
  [string]$GuacAdminPassword = "",
  [switch]$EnableSampleVdiDesktop,
  [switch]$UseRegionalEcrImages,
  [switch]$UseRegionalEcrDesktopImage,
  [string]$EcrAccountId = "",
  [string]$EcrGuacdRepositoryName = "ddc-vdi-guacd",
  [string]$EcrGuacamoleRepositoryName = "ddc-vdi-guacamole",
  [string]$EcrPostgresRepositoryName = "ddc-vdi-postgres",
  [string]$EcrNginxRepositoryName = "ddc-vdi-nginx",
  [string]$EcrDesktopRepositoryName = "ddc-vdi-desktop",
  [switch]$SiteAOnly,
  [switch]$SiteBOnly,
  [switch]$PlanOnly,
  [switch]$SkipKubeconfigUpdate,
  [switch]$SkipRolloutWait,
  [int]$RolloutTimeoutSeconds = 300
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

function Invoke-CommandCheckedRedacted {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Executable,
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments,
    [string]$Label = "",
    [string]$Summary = ""
  )

  $labelPrefix = if ([string]::IsNullOrWhiteSpace($Label)) { "" } else { "[$Label] " }
  $summarySuffix = if ([string]::IsNullOrWhiteSpace($Summary)) { "<redacted>" } else { $Summary }
  Write-Host "$labelPrefix$Executable $summarySuffix"
  & $Executable @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed (exit $LASTEXITCODE): $Executable $summarySuffix"
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

function Get-TerraformOutputJson {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TerraformExecutable,
    [Parameter(Mandatory = $true)]
    [string]$OutputName
  )

  $result = Invoke-CommandCapture -Executable $TerraformExecutable -Arguments @("output", "-json", $OutputName) -Label "terraform-output"
  if ($result.exit_code -ne 0) {
    throw "terraform output -json $OutputName failed: $($result.output)"
  }

  try {
    return ($result.output | ConvertFrom-Json)
  } catch {
    throw "Unable to parse terraform output '$OutputName' as JSON. Error: $($_.Exception.Message)"
  }
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

function New-GuacamolePasswordMaterial {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Password
  )

  $saltBytes = New-Object byte[] 32
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($saltBytes)
  $saltHex = ($saltBytes | ForEach-Object { $_.ToString("X2") }) -join ""

  $sha256 = [System.Security.Cryptography.SHA256]::Create()
  $hashBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Password + $saltHex))
  $hashHex = ($hashBytes | ForEach-Object { $_.ToString("X2") }) -join ""

  return [pscustomobject]@{
    salt_hex = $saltHex
    hash_hex = $hashHex
  }
}

function New-RandomAlphaNumericSecret {
  param(
    [int]$Length = 24
  )

  if ($Length -lt 12) {
    throw "Length must be >= 12."
  }

  $alphabet = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
  $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
  $bytes = New-Object byte[] $Length
  $rng.GetBytes($bytes)

  $chars = New-Object System.Collections.Generic.List[char]
  foreach ($b in $bytes) {
    $chars.Add($alphabet[$b % $alphabet.Length])
  }

  return -join $chars
}

function Escape-SqlLiteral {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Value
  )

  return $Value.Replace("'", "''")
}

function Escape-YamlDoubleQuoted {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Value
  )

  return $Value.Replace("\", "\\").Replace('"', '\"')
}

if ([string]::IsNullOrWhiteSpace($TerraformDir)) {
  $TerraformDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

if (-not (Test-Path $TerraformDir)) {
  throw "TerraformDir does not exist: $TerraformDir"
}

if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
  $ManifestPath = (Resolve-Path (Join-Path $PSScriptRoot "..\..\k8s\vdi\guacamole-nodeport.yaml")).Path
}

if (-not (Test-Path $ManifestPath)) {
  throw "ManifestPath does not exist: $ManifestPath"
}

if ([string]::IsNullOrWhiteSpace($DbInitSqlPath)) {
  $DbInitSqlPath = (Resolve-Path (Join-Path $PSScriptRoot "..\..\k8s\vdi\guacamole-postgresql-init.sql")).Path
}

if (-not (Test-Path $DbInitSqlPath)) {
  throw "DbInitSqlPath does not exist: $DbInitSqlPath"
}

if ([string]::IsNullOrWhiteSpace($DesktopManifestPath)) {
  $DesktopManifestPath = (Resolve-Path (Join-Path $PSScriptRoot "..\..\k8s\vdi\vdi-desktop-vnc.yaml")).Path
}

if ($EnableSampleVdiDesktop -and -not (Test-Path $DesktopManifestPath)) {
  throw "DesktopManifestPath does not exist: $DesktopManifestPath"
}

if ($RolloutTimeoutSeconds -le 0) {
  throw "RolloutTimeoutSeconds must be > 0."
}

if ($SiteAOnly -and $SiteBOnly) {
  throw "SiteAOnly and SiteBOnly cannot both be set."
}

if (-not [string]::IsNullOrWhiteSpace($AwsProfile)) {
  $env:AWS_PROFILE = $AwsProfile
}

$terraform = Get-ToolPath -Name "terraform"
if ($null -eq $terraform) {
  throw "terraform not found in PATH."
}

$aws = Get-ToolPath -Name "aws"
if ($null -eq $aws) {
  throw "aws CLI not found in PATH."
}

$kubectl = Get-ToolPath -Name "kubectl"
if ($null -eq $kubectl) {
  throw "kubectl not found in PATH."
}

$manifestTemplate = Get-Content -Path $ManifestPath -Raw
if (
  $manifestTemplate.IndexOf("__GUACD_IMAGE__", [System.StringComparison]::Ordinal) -lt 0 -or
  $manifestTemplate.IndexOf("__GUACAMOLE_IMAGE__", [System.StringComparison]::Ordinal) -lt 0 -or
  $manifestTemplate.IndexOf("__POSTGRES_IMAGE__", [System.StringComparison]::Ordinal) -lt 0 -or
  $manifestTemplate.IndexOf("__NGINX_IMAGE__", [System.StringComparison]::Ordinal) -lt 0 -or
  $manifestTemplate.IndexOf("__GUACAMOLE_DB_NAME__", [System.StringComparison]::Ordinal) -lt 0 -or
  $manifestTemplate.IndexOf("__GUACAMOLE_DB_USER__", [System.StringComparison]::Ordinal) -lt 0 -or
  $manifestTemplate.IndexOf("__GUACAMOLE_DB_PASSWORD__", [System.StringComparison]::Ordinal) -lt 0
) {
  throw "Manifest template must include image and DB credential placeholders (__GUACD_IMAGE__, __GUACAMOLE_IMAGE__, __POSTGRES_IMAGE__, __NGINX_IMAGE__, __GUACAMOLE_DB_NAME__, __GUACAMOLE_DB_USER__, __GUACAMOLE_DB_PASSWORD__): $ManifestPath"
}

$desktopManifestTemplate = ""
if ($EnableSampleVdiDesktop) {
  $desktopManifestTemplate = Get-Content -Path $DesktopManifestPath -Raw
  if ($desktopManifestTemplate.IndexOf("__VDI_DESKTOP_IMAGE__", [System.StringComparison]::Ordinal) -lt 0 -or $desktopManifestTemplate.IndexOf("__VDI_DESKTOP_PASSWORD__", [System.StringComparison]::Ordinal) -lt 0) {
    throw "Desktop manifest template must include __VDI_DESKTOP_IMAGE__ and __VDI_DESKTOP_PASSWORD__ placeholders: $DesktopManifestPath"
  }
}

$effectiveGuacAdminPassword = $GuacAdminPassword
if ([string]::IsNullOrWhiteSpace($effectiveGuacAdminPassword)) {
  $effectiveGuacAdminPassword = $env:GUACADMIN_PASSWORD
}
if ([string]::IsNullOrWhiteSpace($effectiveGuacAdminPassword)) {
  $effectiveGuacAdminPassword = New-RandomAlphaNumericSecret -Length 32
  Write-Host "Generated a random guacadmin password for this bootstrap run."
}

$effectiveGuacamoleDbName = $GuacamoleDbName
if ([string]::IsNullOrWhiteSpace($effectiveGuacamoleDbName)) {
  $effectiveGuacamoleDbName = "guacamole_db"
}

$effectiveGuacamoleDbUser = $GuacamoleDbUser
if ([string]::IsNullOrWhiteSpace($effectiveGuacamoleDbUser)) {
  $effectiveGuacamoleDbUser = "guacamole_user"
}

$effectiveGuacamoleDbPassword = $GuacamoleDbPassword
if ([string]::IsNullOrWhiteSpace($effectiveGuacamoleDbPassword)) {
  $effectiveGuacamoleDbPassword = $env:GUACAMOLE_DB_PASSWORD
}
if ([string]::IsNullOrWhiteSpace($effectiveGuacamoleDbPassword)) {
  $effectiveGuacamoleDbPassword = New-RandomAlphaNumericSecret -Length 32
  Write-Host "Generated a random Guacamole DB password for this bootstrap run."
}

if ($DesktopVncPort -lt 1 -or $DesktopVncPort -gt 65535) {
  throw "DesktopVncPort must be between 1 and 65535."
}
if ($EnableSampleVdiDesktop -and [string]::IsNullOrWhiteSpace($DesktopConnectionName)) {
  throw "DesktopConnectionName cannot be empty when -EnableSampleVdiDesktop is set."
}

$effectiveDesktopVncPassword = $DesktopVncPassword
if ([string]::IsNullOrWhiteSpace($effectiveDesktopVncPassword)) {
  $effectiveDesktopVncPassword = $env:VDI_DESKTOP_VNC_PASSWORD
}
if ($EnableSampleVdiDesktop -and [string]::IsNullOrWhiteSpace($effectiveDesktopVncPassword)) {
  $effectiveDesktopVncPassword = New-RandomAlphaNumericSecret -Length 24
}

$dbInitTemplate = Get-Content -Path $DbInitSqlPath -Raw
if (
  $dbInitTemplate.IndexOf("__GUACADMIN_PASSWORD_HASH_HEX__", [System.StringComparison]::Ordinal) -lt 0 -or
  $dbInitTemplate.IndexOf("__GUACADMIN_PASSWORD_SALT_HEX__", [System.StringComparison]::Ordinal) -lt 0
) {
  throw "Unable to locate guacadmin password placeholders in DB init SQL template (__GUACADMIN_PASSWORD_HASH_HEX__, __GUACADMIN_PASSWORD_SALT_HEX__): $DbInitSqlPath"
}

$guacPasswordMaterial = New-GuacamolePasswordMaterial -Password $effectiveGuacAdminPassword
$renderedDbInitSql = $dbInitTemplate.Replace("__GUACADMIN_PASSWORD_HASH_HEX__", $guacPasswordMaterial.hash_hex).Replace("__GUACADMIN_PASSWORD_SALT_HEX__", $guacPasswordMaterial.salt_hex)

$guacPasswordRotateSql = "UPDATE guacamole_user u SET password_salt = decode('$($guacPasswordMaterial.salt_hex)', 'hex'), password_hash = decode('$($guacPasswordMaterial.hash_hex)', 'hex'), password_date = CURRENT_TIMESTAMP FROM guacamole_entity e WHERE u.entity_id = e.entity_id AND e.type = 'USER' AND e.name = 'guacadmin';"
$desktopServiceHostname = "vdi-desktop.vdi.svc.cluster.local"

Push-Location $TerraformDir
try {
  Invoke-CommandChecked -Executable $terraform -Arguments @("validate") -Label "terraform-validate"

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

  if (($UseRegionalEcrImages -or $UseRegionalEcrDesktopImage) -and [string]::IsNullOrWhiteSpace($EcrAccountId)) {
    $accountResult = Invoke-CommandCapture -Executable $aws -Arguments @("sts", "get-caller-identity", "--query", "Account", "--output", "text") -Label "aws-account"
    if ($accountResult.exit_code -ne 0 -or [string]::IsNullOrWhiteSpace($accountResult.output)) {
      throw "Unable to resolve AWS account ID for regional ECR image mode. Error: $($accountResult.output)"
    }
    $EcrAccountId = $accountResult.output.Trim()
  }

  $guacdTag = Get-ImageTag -Image $GuacdImage
  $guacamoleTag = Get-ImageTag -Image $GuacamoleImage
  $postgresTag = Get-ImageTag -Image $PostgresImage
  $nginxTag = Get-ImageTag -Image $NginxImage

  $targets = @()
  if (-not $SiteBOnly) {
    $targets += [pscustomobject]@{ site = "site-a"; region = $siteARegion; cluster = $siteACluster; context = "ddc-site-a" }
  }
  if (-not $SiteAOnly) {
    $targets += [pscustomobject]@{ site = "site-b"; region = $siteBRegion; cluster = $siteBCluster; context = "ddc-site-b" }
  }

  foreach ($target in $targets) {
    $effectiveGuacdImage = $GuacdImage
    $effectiveGuacamoleImage = $GuacamoleImage
    $effectivePostgresImage = $PostgresImage
    $effectiveNginxImage = $NginxImage
    $effectiveDesktopImage = $DesktopImage
    if ($UseRegionalEcrImages) {
      $registry = "{0}.dkr.ecr.{1}.amazonaws.com" -f $EcrAccountId, $target.region
      $effectiveGuacdImage = "$registry/${EcrGuacdRepositoryName}:$guacdTag"
      $effectiveGuacamoleImage = "$registry/${EcrGuacamoleRepositoryName}:$guacamoleTag"
      $effectivePostgresImage = "$registry/${EcrPostgresRepositoryName}:$postgresTag"
      $effectiveNginxImage = "$registry/${EcrNginxRepositoryName}:$nginxTag"
    }
    if ($UseRegionalEcrDesktopImage) {
      $registry = "{0}.dkr.ecr.{1}.amazonaws.com" -f $EcrAccountId, $target.region
      $desktopTag = Get-ImageTag -Image $DesktopImage
      $effectiveDesktopImage = "$registry/${EcrDesktopRepositoryName}:$desktopTag"
    }

    $escapedGuacamoleDbName = Escape-YamlDoubleQuoted -Value $effectiveGuacamoleDbName
    $escapedGuacamoleDbUser = Escape-YamlDoubleQuoted -Value $effectiveGuacamoleDbUser
    $escapedGuacamoleDbPassword = Escape-YamlDoubleQuoted -Value $effectiveGuacamoleDbPassword
    $renderedManifest = $manifestTemplate.Replace("__GUACD_IMAGE__", $effectiveGuacdImage).Replace("__GUACAMOLE_IMAGE__", $effectiveGuacamoleImage).Replace("__POSTGRES_IMAGE__", $effectivePostgresImage).Replace("__NGINX_IMAGE__", $effectiveNginxImage).Replace("__GUACAMOLE_DB_NAME__", $escapedGuacamoleDbName).Replace("__GUACAMOLE_DB_USER__", $escapedGuacamoleDbUser).Replace("__GUACAMOLE_DB_PASSWORD__", $escapedGuacamoleDbPassword)
    $renderedDesktopManifest = ""
    if ($EnableSampleVdiDesktop) {
      $renderedDesktopManifest = $desktopManifestTemplate.Replace("__VDI_DESKTOP_IMAGE__", $effectiveDesktopImage).Replace("__VDI_DESKTOP_PASSWORD__", $effectiveDesktopVncPassword)
    }
    $tempManifestPath = Join-Path ([System.IO.Path]::GetTempPath()) ("ddc-vdi-manifest-" + [guid]::NewGuid().ToString("N") + ".yaml")
    $tempDbInitSqlPath = Join-Path ([System.IO.Path]::GetTempPath()) ("ddc-vdi-db-init-" + [guid]::NewGuid().ToString("N") + ".sql")
    $tempDesktopManifestPath = Join-Path ([System.IO.Path]::GetTempPath()) ("ddc-vdi-desktop-" + [guid]::NewGuid().ToString("N") + ".yaml")
    Set-Content -Path $tempManifestPath -Value $renderedManifest
    Set-Content -Path $tempDbInitSqlPath -Value $renderedDbInitSql
    if ($EnableSampleVdiDesktop) {
      Set-Content -Path $tempDesktopManifestPath -Value $renderedDesktopManifest
    }

    try {
      Write-Host ""
      Write-Host "== VDI service bootstrap: $($target.site) =="
      Write-Host "Cluster: $($target.cluster) | Region: $($target.region) | Context: $($target.context)"
      Write-Host "Images: postgres=$effectivePostgresImage ; guacd=$effectiveGuacdImage ; guacamole=$effectiveGuacamoleImage ; nginx=$effectiveNginxImage"
      if ($EnableSampleVdiDesktop) {
        Write-Host "Desktop image: $effectiveDesktopImage"
      }

      if (-not $SkipKubeconfigUpdate) {
        Invoke-CommandChecked -Executable $aws -Arguments @("eks", "update-kubeconfig", "--name", $target.cluster, "--region", $target.region, "--alias", $target.context) -Label "$($target.site)-kubeconfig"
      } else {
        Write-Host "Skipping kubeconfig update by request."
      }

      $vdiNodes = Invoke-CommandCapture -Executable $kubectl -Arguments @("--context", $target.context, "get", "nodes", "-l", "workload=vdi", "-o", "name") -Label "$($target.site)-vdi-nodes"
      if ($vdiNodes.exit_code -ne 0) {
        Write-Warning "Unable to list workload=vdi nodes in $($target.context): $($vdiNodes.output)"
      } elseif ([string]::IsNullOrWhiteSpace($vdiNodes.output)) {
        Write-Warning "No workload=vdi nodes found in $($target.context). Deployment may remain pending."
      } else {
        $nodeCount = @($vdiNodes.output -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
        Write-Host "Detected workload=vdi nodes: $nodeCount"
      }

      if ($PlanOnly) {
        Invoke-CommandChecked -Executable $kubectl -Arguments @("--context", $target.context, "apply", "--dry-run=client", "-f", $tempManifestPath) -Label "$($target.site)-apply-dryrun"
        if ($EnableSampleVdiDesktop) {
          Invoke-CommandChecked -Executable $kubectl -Arguments @("--context", $target.context, "apply", "--dry-run=client", "-f", $tempDesktopManifestPath) -Label "$($target.site)-desktop-apply-dryrun"
        }
        continue
      }

      Invoke-CommandChecked -Executable $kubectl -Arguments @("--context", $target.context, "create", "namespace", "vdi", "--dry-run=client", "-o", "yaml") -Label "$($target.site)-ns-dryrun"
      $nsYaml = Invoke-CommandCapture -Executable $kubectl -Arguments @("--context", $target.context, "create", "namespace", "vdi", "--dry-run=client", "-o", "yaml") -Label "$($target.site)-ns-yaml"
      if ($nsYaml.exit_code -ne 0 -or [string]::IsNullOrWhiteSpace($nsYaml.output)) {
        throw "Unable to generate namespace manifest for vdi in $($target.context). Error: $($nsYaml.output)"
      }
      $tempNsPath = Join-Path ([System.IO.Path]::GetTempPath()) ("ddc-vdi-namespace-" + [guid]::NewGuid().ToString("N") + ".yaml")
      Set-Content -Path $tempNsPath -Value $nsYaml.output
      try {
        Invoke-CommandChecked -Executable $kubectl -Arguments @("--context", $target.context, "apply", "-f", $tempNsPath) -Label "$($target.site)-ns-apply"
      } finally {
        if (Test-Path $tempNsPath) {
          Remove-Item -Path $tempNsPath -Force
        }
      }

      $configMapYaml = Invoke-CommandCapture -Executable $kubectl -Arguments @("--context", $target.context, "-n", "vdi", "create", "configmap", "guacamole-db-init", "--from-file", ("001-guacamole.sql={0}" -f $tempDbInitSqlPath), "--dry-run=client", "-o", "yaml") -Label "$($target.site)-cm-yaml"
      if ($configMapYaml.exit_code -ne 0 -or [string]::IsNullOrWhiteSpace($configMapYaml.output)) {
        throw "Unable to generate guacamole-db-init ConfigMap manifest in $($target.context). Error: $($configMapYaml.output)"
      }
      $tempCmPath = Join-Path ([System.IO.Path]::GetTempPath()) ("ddc-vdi-configmap-" + [guid]::NewGuid().ToString("N") + ".yaml")
      Set-Content -Path $tempCmPath -Value $configMapYaml.output
      try {
        Invoke-CommandChecked -Executable $kubectl -Arguments @("--context", $target.context, "apply", "-f", $tempCmPath) -Label "$($target.site)-cm-apply"
      } finally {
        if (Test-Path $tempCmPath) {
          Remove-Item -Path $tempCmPath -Force
        }
      }

      Invoke-CommandChecked -Executable $kubectl -Arguments @("--context", $target.context, "apply", "-f", $tempManifestPath) -Label "$($target.site)-apply"
      if (-not $SkipRolloutWait) {
        Invoke-CommandChecked -Executable $kubectl -Arguments @("--context", $target.context, "-n", "vdi", "rollout", "status", "deployment/guacamole-db", "--timeout", ("{0}s" -f $RolloutTimeoutSeconds)) -Label "$($target.site)-rollout-db"
        Invoke-CommandChecked -Executable $kubectl -Arguments @("--context", $target.context, "-n", "vdi", "rollout", "status", "deployment/guacamole", "--timeout", ("{0}s" -f $RolloutTimeoutSeconds)) -Label "$($target.site)-rollout"
      } else {
        Write-Host "Skipping rollout wait by request."
      }
      Invoke-CommandCheckedRedacted -Executable $kubectl -Arguments @("--context", $target.context, "-n", "vdi", "exec", "deployment/guacamole-db", "--", "psql", "-U", $effectiveGuacamoleDbUser, "-d", $effectiveGuacamoleDbName, "-v", "ON_ERROR_STOP=1", "-c", $guacPasswordRotateSql) -Label "$($target.site)-rotate-guacadmin" -Summary "--context $($target.context) -n vdi exec deployment/guacamole-db -- psql ... -c <redacted-sql>"
      if ($EnableSampleVdiDesktop) {
        Invoke-CommandChecked -Executable $kubectl -Arguments @("--context", $target.context, "apply", "-f", $tempDesktopManifestPath) -Label "$($target.site)-desktop-apply"
        if (-not $SkipRolloutWait) {
          Invoke-CommandChecked -Executable $kubectl -Arguments @("--context", $target.context, "-n", "vdi", "rollout", "status", "deployment/vdi-desktop", "--timeout", ("{0}s" -f $RolloutTimeoutSeconds)) -Label "$($target.site)-desktop-rollout"
        }

        $escapedConnectionName = Escape-SqlLiteral -Value $DesktopConnectionName
        $escapedDesktopHost = Escape-SqlLiteral -Value $desktopServiceHostname
        $escapedDesktopPassword = Escape-SqlLiteral -Value $effectiveDesktopVncPassword
        $desktopConnectionSqlTemplate = @'
DO $$
DECLARE
  v_connection_id integer;
  v_entity_id integer;
BEGIN
  SELECT connection_id INTO v_connection_id
  FROM guacamole_connection
  WHERE connection_name = '__CONNECTION_NAME__'
    AND parent_id IS NULL
  ORDER BY connection_id
  LIMIT 1;

  IF v_connection_id IS NULL THEN
    INSERT INTO guacamole_connection (connection_name, protocol)
    VALUES ('__CONNECTION_NAME__', 'vnc')
    RETURNING connection_id INTO v_connection_id;
  ELSE
    UPDATE guacamole_connection
    SET protocol = 'vnc'
    WHERE connection_id = v_connection_id;
  END IF;

  DELETE FROM guacamole_connection_parameter
  WHERE connection_id = v_connection_id
    AND parameter_name IN ('hostname', 'port', 'password', 'read-only');

  INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
  VALUES
    (v_connection_id, 'hostname', '__DESKTOP_HOST__'),
    (v_connection_id, 'port', '__DESKTOP_PORT__'),
    (v_connection_id, 'password', '__DESKTOP_PASSWORD__'),
    (v_connection_id, 'read-only', 'false')
  ON CONFLICT (connection_id, parameter_name) DO UPDATE
    SET parameter_value = EXCLUDED.parameter_value;

  SELECT entity_id INTO v_entity_id
  FROM guacamole_entity
  WHERE name = 'guacadmin'
    AND type = 'USER'
  LIMIT 1;

  IF v_entity_id IS NOT NULL THEN
    INSERT INTO guacamole_connection_permission (entity_id, connection_id, permission)
    VALUES
      (v_entity_id, v_connection_id, 'READ'::guacamole_object_permission_type),
      (v_entity_id, v_connection_id, 'UPDATE'::guacamole_object_permission_type),
      (v_entity_id, v_connection_id, 'DELETE'::guacamole_object_permission_type),
      (v_entity_id, v_connection_id, 'ADMINISTER'::guacamole_object_permission_type)
    ON CONFLICT DO NOTHING;
  END IF;
END
$$;
'@
        $desktopConnectionSql = $desktopConnectionSqlTemplate.Replace("__CONNECTION_NAME__", $escapedConnectionName).Replace("__DESKTOP_HOST__", $escapedDesktopHost).Replace("__DESKTOP_PORT__", [string]$DesktopVncPort).Replace("__DESKTOP_PASSWORD__", $escapedDesktopPassword)
        Invoke-CommandCheckedRedacted -Executable $kubectl -Arguments @("--context", $target.context, "-n", "vdi", "exec", "deployment/guacamole-db", "--", "psql", "-U", $effectiveGuacamoleDbUser, "-d", $effectiveGuacamoleDbName, "-v", "ON_ERROR_STOP=1", "-c", $desktopConnectionSql) -Label "$($target.site)-desktop-seed-guac-connection" -Summary "--context $($target.context) -n vdi exec deployment/guacamole-db -- psql ... -c <redacted-sql>"
        Invoke-CommandChecked -Executable $kubectl -Arguments @("--context", $target.context, "-n", "vdi", "get", "service", "vdi-desktop", "-o", "wide") -Label "$($target.site)-desktop-service"
      }
      Invoke-CommandChecked -Executable $kubectl -Arguments @("--context", $target.context, "-n", "vdi", "get", "service", "guacamole-nodeport", "-o", "wide") -Label "$($target.site)-service"
    } finally {
      if (Test-Path $tempManifestPath) {
        Remove-Item -Path $tempManifestPath -Force
      }
      if (Test-Path $tempDbInitSqlPath) {
        Remove-Item -Path $tempDbInitSqlPath -Force
      }
      if (Test-Path $tempDesktopManifestPath) {
        Remove-Item -Path $tempDesktopManifestPath -Force
      }
    }
  }

  if ($EnableSampleVdiDesktop) {
    Write-Host ""
    Write-Host "Sample VDI desktop has been deployed and registered in Guacamole."
    Write-Host "Connection name: $DesktopConnectionName"
    Write-Host "VNC service host: $desktopServiceHostname"
    Write-Host "VNC port: $DesktopVncPort"
    Write-Host "VNC password is stored in Kubernetes secret 'vdi/vdi-desktop-auth'."
  }
} finally {
  Pop-Location
}
