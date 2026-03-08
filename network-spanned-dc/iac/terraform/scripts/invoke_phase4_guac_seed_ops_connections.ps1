param(
  [string]$TerraformDir = "",
  [string]$AwsProfile = "",
  [string]$GuacamoleDbName = "",
  [string]$GuacamoleDbUser = "",
  [string]$SshPassword = "",
  [switch]$SiteAOnly,
  [switch]$SiteBOnly,
  [switch]$PlanOnly,
  [switch]$SkipKubeconfigUpdate
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

function Escape-SqlLiteral {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Value
  )

  return $Value.Replace("'", "''")
}

if ([string]::IsNullOrWhiteSpace($TerraformDir)) {
  $TerraformDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

if (-not (Test-Path $TerraformDir)) {
  throw "TerraformDir does not exist: $TerraformDir"
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

Push-Location $TerraformDir
try {
  Invoke-CommandChecked -Executable $terraform -Arguments @("validate") -Label "terraform-validate"

  $siteARegion = Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "aws_site_a_region" -DefaultValue "us-east-1"
  $siteBRegion = Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "aws_site_b_region" -DefaultValue "us-west-2"
  $namePrefix = Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "name_prefix" -DefaultValue "ddc"
  $environment = Get-TfvarsStringValue -TerraformDirectory $TerraformDir -VariableName "environment" -DefaultValue "proposal"

  $effectiveGuacamoleDbName = if ([string]::IsNullOrWhiteSpace($GuacamoleDbName)) { "guacamole_db" } else { $GuacamoleDbName }
  $effectiveGuacamoleDbUser = if ([string]::IsNullOrWhiteSpace($GuacamoleDbUser)) { "guacamole_user" } else { $GuacamoleDbUser }

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
    Write-Warning "Unable to read phase3_aws_eks_clusters from Terraform output; using naming fallback."
  }

  $opsServers = Get-TerraformOutputJson -TerraformExecutable $terraform -OutputName "phase4_ops_servers"
  if ($null -eq $opsServers) {
    throw "phase4_ops_servers output is null. Enable and apply phase4_enable_ops_stack before seeding Guacamole connections."
  }

  $connections = New-Object System.Collections.Generic.List[object]

  if ($null -ne $opsServers.openproject -and -not [string]::IsNullOrWhiteSpace($opsServers.openproject.private_ip)) {
    $connections.Add([pscustomobject]@{
      name     = if ([string]::IsNullOrWhiteSpace($opsServers.openproject.guac_target)) { "OpenProject (Site C)" } else { [string]$opsServers.openproject.guac_target }
      hostname = [string]$opsServers.openproject.private_ip
      port     = if ($null -eq $opsServers.openproject.ssh_port) { 22 } else { [int]$opsServers.openproject.ssh_port }
      username = if ([string]::IsNullOrWhiteSpace($opsServers.openproject.ssh_user)) { "opsadmin" } else { [string]$opsServers.openproject.ssh_user }
    })
  }

  if ($null -ne $opsServers.git -and -not [string]::IsNullOrWhiteSpace($opsServers.git.private_ip)) {
    $connections.Add([pscustomobject]@{
      name     = if ([string]::IsNullOrWhiteSpace($opsServers.git.guac_target)) { "Git Server (Site B)" } else { [string]$opsServers.git.guac_target }
      hostname = [string]$opsServers.git.private_ip
      port     = if ($null -eq $opsServers.git.ssh_port) { 2222 } else { [int]$opsServers.git.ssh_port }
      username = if ([string]::IsNullOrWhiteSpace($opsServers.git.ssh_user)) { "opsadmin" } else { [string]$opsServers.git.ssh_user }
    })
  }

  if ($null -ne $opsServers.ansible -and -not [string]::IsNullOrWhiteSpace($opsServers.ansible.private_ip)) {
    $connections.Add([pscustomobject]@{
      name     = if ([string]::IsNullOrWhiteSpace($opsServers.ansible.guac_target)) { "Ansible Control (Site A)" } else { [string]$opsServers.ansible.guac_target }
      hostname = [string]$opsServers.ansible.private_ip
      port     = if ($null -eq $opsServers.ansible.ssh_port) { 22 } else { [int]$opsServers.ansible.ssh_port }
      username = if ([string]::IsNullOrWhiteSpace($opsServers.ansible.ssh_user)) { "opsadmin" } else { [string]$opsServers.ansible.ssh_user }
    })
  }

  if ($connections.Count -eq 0) {
    throw "No SSH targets were found in phase4_ops_servers output."
  }

  $targets = @()
  if (-not $SiteBOnly) {
    $targets += [pscustomobject]@{ site = "site-a"; region = $siteARegion; cluster = $siteACluster; context = "ddc-site-a" }
  }
  if (-not $SiteAOnly) {
    $targets += [pscustomobject]@{ site = "site-b"; region = $siteBRegion; cluster = $siteBCluster; context = "ddc-site-b" }
  }

  foreach ($target in $targets) {
    Write-Host ""
    Write-Host "== Seed Guacamole ops connections: $($target.site) =="
    Write-Host "Cluster: $($target.cluster) | Region: $($target.region) | Context: $($target.context)"

    if (-not $SkipKubeconfigUpdate) {
      Invoke-CommandChecked -Executable $aws -Arguments @("eks", "update-kubeconfig", "--name", $target.cluster, "--region", $target.region, "--alias", $target.context) -Label "$($target.site)-kubeconfig"
    } else {
      Write-Host "Skipping kubeconfig update by request."
    }

    foreach ($connection in $connections) {
      Write-Host "Connection: $($connection.name) -> $($connection.hostname):$($connection.port) (user=$($connection.username))"
      if ($PlanOnly) {
        continue
      }

      $escapedName = Escape-SqlLiteral -Value $connection.name
      $escapedHost = Escape-SqlLiteral -Value $connection.hostname
      $escapedUser = Escape-SqlLiteral -Value $connection.username
      $escapedPort = Escape-SqlLiteral -Value ([string]$connection.port)
      $escapedPassword = Escape-SqlLiteral -Value $SshPassword
      $passwordDeleteClause = ""
      $passwordInsertClause = ""
      if (-not [string]::IsNullOrWhiteSpace($SshPassword)) {
        $passwordDeleteClause = ", 'password'"
        $passwordInsertClause = ", (v_connection_id, 'password', '__PASSWORD__')"
      }

      $seedSqlTemplate = @'
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
    VALUES ('__CONNECTION_NAME__', 'ssh')
    RETURNING connection_id INTO v_connection_id;
  ELSE
    UPDATE guacamole_connection
    SET protocol = 'ssh'
    WHERE connection_id = v_connection_id;
  END IF;

  DELETE FROM guacamole_connection_parameter
  WHERE connection_id = v_connection_id
    AND parameter_name IN ('hostname', 'port', 'username'__PASSWORD_PARAM_DELETE__);

  INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value)
  VALUES
    (v_connection_id, 'hostname', '__HOSTNAME__'),
    (v_connection_id, 'port', '__PORT__'),
    (v_connection_id, 'username', '__USERNAME__')__PASSWORD_PARAM_INSERT__
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
      $seedSql = $seedSqlTemplate.Replace("__CONNECTION_NAME__", $escapedName).Replace("__HOSTNAME__", $escapedHost).Replace("__PORT__", $escapedPort).Replace("__USERNAME__", $escapedUser).Replace("__PASSWORD__", $escapedPassword).Replace("__PASSWORD_PARAM_DELETE__", $passwordDeleteClause).Replace("__PASSWORD_PARAM_INSERT__", $passwordInsertClause)

      Invoke-CommandCheckedRedacted -Executable $kubectl -Arguments @("--context", $target.context, "-n", "vdi", "exec", "deployment/guacamole-db", "--", "psql", "-U", $effectiveGuacamoleDbUser, "-d", $effectiveGuacamoleDbName, "-v", "ON_ERROR_STOP=1", "-c", $seedSql) -Label "$($target.site)-seed-$($connection.name)" -Summary "--context $($target.context) -n vdi exec deployment/guacamole-db -- psql ... -c <redacted-sql>"
    }

    if (-not $PlanOnly) {
      Invoke-CommandChecked -Executable $kubectl -Arguments @("--context", $target.context, "-n", "vdi", "get", "service", "guacamole-nodeport", "-o", "wide") -Label "$($target.site)-service"
    }
  }
} finally {
  Pop-Location
}
