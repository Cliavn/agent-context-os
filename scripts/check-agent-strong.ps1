[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Issues = New-Object System.Collections.Generic.List[string]

function Add-Issue {
    param([string]$Message)
    $Issues.Add($Message) | Out-Null
}

function Invoke-GitCheck {
    param(
        [string]$Label,
        [string[]]$Arguments
    )

    $PreviousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $Output = & git @Arguments 2>&1
        $ExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $PreviousErrorActionPreference
    }

    if ($ExitCode -ne 0) {
        Add-Issue "$Label failed: git $($Arguments -join ' ')"
        foreach ($Line in $Output) {
            Add-Issue "  $Line"
        }
    }
}

function Invoke-CheckScript {
    param(
        [string]$RelativePath,
        [string[]]$Arguments = @()
    )

    $Path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Write-Host "Strong check skipped: $RelativePath not found."
        return
    }

    $PreviousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $Output = & powershell -NoProfile -ExecutionPolicy Bypass -File $Path @Arguments 2>&1
        $ExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $PreviousErrorActionPreference
    }

    if ($ExitCode -ne 0) {
        Add-Issue "Check script failed: $RelativePath"
        foreach ($Line in $Output) {
            Add-Issue "  $Line"
        }
    }
}

Push-Location $Root
try {
    Invoke-GitCheck "Working tree whitespace check" @("diff", "--check", "--")
    Invoke-GitCheck "Staged whitespace check" @("diff", "--cached", "--check", "--")

    Invoke-CheckScript "scripts/check-agent-context-os.ps1"
    Invoke-CheckScript "scripts/check-agent-project.ps1" @("-ProjectRoot", "templates/project", "-AllowPlaceholders")
    Invoke-CheckScript "scripts/check-agent-worktrees.ps1"
    Invoke-CheckScript "scripts/check-agent-drift.ps1"
}
finally {
    Pop-Location
}

if ($Issues.Count -gt 0) {
    Write-Host "Agent strong check failed:" -ForegroundColor Red
    foreach ($Issue in $Issues) {
        Write-Host (" - " + $Issue) -ForegroundColor Red
    }
    exit 1
}

Write-Host "Agent strong check passed." -ForegroundColor Green
exit 0
