[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$AllowPlaceholders
)

$ErrorActionPreference = "Stop"

try {
    $ResolvedProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
}
catch {
    Write-Host "Agent project check failed: project root not found: $ProjectRoot" -ForegroundColor Red
    exit 1
}

$ProjectCheck = Join-Path $ResolvedProjectRoot "scripts/check-agent.ps1"
if (-not (Test-Path -LiteralPath $ProjectCheck -PathType Leaf)) {
    Write-Host "Agent project check failed: scripts/check-agent.ps1 not found in $ResolvedProjectRoot" -ForegroundColor Red
    exit 1
}

$Arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $ProjectCheck, "-ProjectRoot", $ResolvedProjectRoot)
if ($AllowPlaceholders) {
    $Arguments += "-AllowPlaceholders"
}

$Output = & powershell @Arguments 2>&1
$ExitCode = $LASTEXITCODE
foreach ($Line in $Output) {
    Write-Host $Line
}

exit $ExitCode
