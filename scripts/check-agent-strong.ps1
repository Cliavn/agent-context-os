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

function Invoke-ExpectedFailureScript {
    param(
        [string]$RelativePath,
        [string[]]$Arguments = @(),
        [string]$ExpectedText = ""
    )

    $Path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Add-Issue "Expected-failure check script not found: $RelativePath"
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

    if ($ExitCode -eq 0) {
        Add-Issue "Expected check script to fail but it passed: $RelativePath $($Arguments -join ' ')"
        return
    }

    if (-not [string]::IsNullOrWhiteSpace($ExpectedText)) {
        $JoinedOutput = ($Output -join "`n")
        if ($JoinedOutput -notlike "*$ExpectedText*") {
            Add-Issue "Expected failure from $RelativePath did not mention '$ExpectedText'"
            foreach ($Line in $Output) {
                Add-Issue "  $Line"
            }
        }
    }
}

function New-ProjectFixture {
    param(
        [string]$ProjectId,
        [string]$ProjectName,
        [string]$MemoryLine
    )

    $FixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-context-os-check-" + [guid]::NewGuid().ToString("N"))
    Copy-Item -LiteralPath (Join-Path $Root "templates/project") -Destination $FixtureRoot -Recurse

    $ConfigPath = Join-Path $FixtureRoot ".agent-context/config.json"
    $Config = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $Config.project_id = $ProjectId
    $Config.project_name = $ProjectName
    $Config.engine.version = "1.0.0"
    $Config.engine.source = "agent-context-os"
    $Config.memory.source_paths = @(".agent-context/memory-sources/memory-*.jsonl")
    $Config.memory.local_index.provider = "embedded-vector-index"
    $Config.memory.local_index.path = ".agent-context/local-index"
    $Config.quality.validation_commands = @("scripts/check-agent.ps1")
    $Config | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ConfigPath -Encoding UTF8

    $MemoryPath = Join-Path $FixtureRoot ".agent-context/memory-sources/memory-bootstrap.jsonl"
    Set-Content -LiteralPath $MemoryPath -Value $MemoryLine -Encoding UTF8

    return $FixtureRoot
}

$TempFixtures = New-Object System.Collections.Generic.List[string]

Push-Location $Root
try {
    Invoke-GitCheck "Working tree whitespace check" @("diff", "--check", "--")
    Invoke-GitCheck "Staged whitespace check" @("diff", "--cached", "--check", "--")

    Invoke-CheckScript "scripts/check-agent-context-os.ps1"
    Invoke-CheckScript "scripts/check-agent-project.ps1" @("-ProjectRoot", "templates/project", "-AllowPlaceholders")
    Invoke-CheckScript "scripts/check-agent-worktrees.ps1"
    Invoke-CheckScript "scripts/check-agent-drift.ps1"
    Invoke-ExpectedFailureScript "scripts/check-agent-project.ps1" @("-ProjectRoot", "templates/project") "placeholder"

    $ValidMemory = '{"id":"mem-20260720-001","status":"current","type":"business_rule","scope":["upgrade"],"summary":"Thin launcher is the only project agent entry.","source":{"kind":"user_confirmed","ref":"AGENTS.md","date":"2026-07-20"},"evidence":["AGENTS.md"],"confidence":"high","last_verified":"2026-07-20","tags":["upgrade"]}'
    $ValidFixture = New-ProjectFixture "valid-project" "Valid Project" $ValidMemory
    $TempFixtures.Add($ValidFixture) | Out-Null
    Invoke-CheckScript "scripts/check-agent-project.ps1" @("-ProjectRoot", $ValidFixture)

    $SensitiveMemory = '{"id":"mem-20260720-002","status":"current","type":"business_rule","scope":["upgrade"],"summary":"Do not write token values into memory sources.","source":{"kind":"user_confirmed","ref":"AGENTS.md","date":"2026-07-20"},"evidence":["AGENTS.md"],"confidence":"high","last_verified":"2026-07-20","tags":["upgrade"]}'
    $SensitiveFixture = New-ProjectFixture "sensitive-project" "Sensitive Project" $SensitiveMemory
    $TempFixtures.Add($SensitiveFixture) | Out-Null
    Invoke-ExpectedFailureScript "scripts/check-agent-project.ps1" @("-ProjectRoot", $SensitiveFixture) "sensitive marker"

    $ChineseSensitiveMemory = '{"id":"mem-20260720-003","status":"current","type":"business_rule","scope":["upgrade"],"summary":"Do not write \u5bc6\u7801 into memory sources.","source":{"kind":"user_confirmed","ref":"AGENTS.md","date":"2026-07-20"},"evidence":["AGENTS.md"],"confidence":"high","last_verified":"2026-07-20","tags":["upgrade"]}'
    $ChineseSensitiveFixture = New-ProjectFixture "chinese-sensitive-project" "Chinese Sensitive Project" $ChineseSensitiveMemory
    $TempFixtures.Add($ChineseSensitiveFixture) | Out-Null
    Invoke-ExpectedFailureScript "scripts/check-agent-project.ps1" @("-ProjectRoot", $ChineseSensitiveFixture) "sensitive marker"
}
finally {
    Pop-Location

    foreach ($Fixture in $TempFixtures) {
        if (Test-Path -LiteralPath $Fixture -PathType Container) {
            $ResolvedFixture = (Resolve-Path -LiteralPath $Fixture).Path
            $ResolvedTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
            if ($ResolvedFixture.StartsWith($ResolvedTemp, [System.StringComparison]::OrdinalIgnoreCase)) {
                Remove-Item -LiteralPath $ResolvedFixture -Recurse -Force
            }
        }
    }
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
