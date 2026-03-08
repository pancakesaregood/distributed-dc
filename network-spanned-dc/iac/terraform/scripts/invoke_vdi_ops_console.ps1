param(
  [string]$TerraformDir = "",
  [string]$BindHost = "127.0.0.1",
  [int]$Port = 8099,
  [int]$CommandTimeoutSeconds = 25,
  [string]$AdminUsername = "",
  [string]$AdminPassword = "",
  [switch]$OpenBrowser
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

if ([string]::IsNullOrWhiteSpace($TerraformDir)) {
  $TerraformDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

if (-not (Test-Path $TerraformDir)) {
  throw "TerraformDir does not exist: $TerraformDir"
}

$serverPath = (Resolve-Path (Join-Path $PSScriptRoot "..\tools\vdi_ops_console\server.py")).Path
if (-not (Test-Path $serverPath)) {
  throw "Ops console server script not found: $serverPath"
}

if ([string]::IsNullOrWhiteSpace($AdminUsername)) {
  $AdminUsername = $env:VDI_ADMIN_USERNAME
}
if ([string]::IsNullOrWhiteSpace($AdminPassword)) {
  $AdminPassword = $env:VDI_ADMIN_PASSWORD
}
if ([string]::IsNullOrWhiteSpace($AdminUsername) -or [string]::IsNullOrWhiteSpace($AdminPassword)) {
  throw "Admin credentials are required. Pass -AdminUsername/-AdminPassword or set VDI_ADMIN_USERNAME/VDI_ADMIN_PASSWORD."
}

$python = Get-ToolPath -Name "python"
if ($null -eq $python) {
  throw "python not found in PATH."
}

$env:VDI_ADMIN_USERNAME = $AdminUsername
$env:VDI_ADMIN_PASSWORD = $AdminPassword
$env:VDI_TERRAFORM_DIR = $TerraformDir
$env:VDI_OPS_HOST = $BindHost
$env:VDI_OPS_PORT = [string]$Port
$env:VDI_OPS_COMMAND_TIMEOUT_SECONDS = [string]$CommandTimeoutSeconds

$url = "http://{0}:{1}" -f $BindHost, $Port
Write-Host "VDI Ops Console starting at $url"
Write-Host "Auth mode: HTTP Basic (admin credentials required)."

if ($OpenBrowser) {
  Start-Process $url | Out-Null
}

& $python $serverPath --host $BindHost --port $Port --terraform-dir $TerraformDir --command-timeout-seconds $CommandTimeoutSeconds
if ($LASTEXITCODE -ne 0) {
  throw "Ops console exited with code $LASTEXITCODE"
}
