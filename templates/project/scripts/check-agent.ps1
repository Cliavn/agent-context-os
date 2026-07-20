[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$AllowPlaceholders
)

$ErrorActionPreference = "Stop"
$Issues = New-Object System.Collections.Generic.List[string]

function Add-Issue {
    param([string]$Message)
    $Issues.Add($Message) | Out-Null
}

function Test-RequiredFile {
    param([string]$RelativePath)
    $Path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Add-Issue "Missing file: $RelativePath"
    }
}

function Test-RequiredDirectory {
    param([string]$RelativePath)
    $Path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        Add-Issue "Missing directory: $RelativePath"
    }
}

function Test-ContainsText {
    param(
        [string]$RelativePath,
        [string]$ExpectedText
    )

    $Path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return
    }

    $Content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if (-not $Content.Contains($ExpectedText)) {
        Add-Issue "File '$RelativePath' does not reference '$ExpectedText'"
    }
}

function Test-NonPlaceholder {
    param(
        [string]$Value,
        [string]$Field
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        Add-Issue "$Field must not be empty"
        return
    }

    if (-not $AllowPlaceholders -and $Value.Contains("<")) {
        Add-Issue "$Field still contains a placeholder"
    }
}

function Test-MemorySourceLine {
    param(
        [string]$Path,
        [string]$Line,
        [int]$LineNumber
    )

    try {
        $Record = $Line | ConvertFrom-Json
    }
    catch {
        Add-Issue "$Path line $LineNumber is not valid JSON: $($_.Exception.Message)"
        return
    }

    foreach ($Field in @("id", "status", "type", "scope", "summary", "source", "confidence", "last_verified")) {
        if (-not ($Record.PSObject.Properties.Name -contains $Field)) {
            Add-Issue "$Path line $LineNumber missing field '$Field'"
        }
    }

    if ($Record.status -and @("current", "draft", "assumption", "stale", "deprecated") -notcontains $Record.status) {
        Add-Issue "$Path line $LineNumber has invalid status '$($Record.status)'"
    }

    if ($Record.confidence -and @("high", "medium", "low") -notcontains $Record.confidence) {
        Add-Issue "$Path line $LineNumber has invalid confidence '$($Record.confidence)'"
    }
}

try {
    $Root = (Resolve-Path -LiteralPath $ProjectRoot).Path
}
catch {
    Write-Host "Agent project check failed: project root not found: $ProjectRoot" -ForegroundColor Red
    exit 1
}

Test-RequiredFile "AGENTS.md"
Test-RequiredFile ".agent-context/config.json"
Test-RequiredDirectory ".agent-context/memory-sources"
Test-RequiredFile ".agent-context/memory-sources/README.md"
Test-RequiredFile ".gitignore"

Test-ContainsText "AGENTS.md" ".agent-context/config.json"
Test-ContainsText "AGENTS.md" "local-index"
Test-ContainsText ".gitignore" ".agent-context/local-index/"
Test-ContainsText ".gitignore" ".agent-context/cache/"

$ConfigPath = Join-Path $Root ".agent-context/config.json"
if (Test-Path -LiteralPath $ConfigPath -PathType Leaf) {
    try {
        $Config = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        Add-Issue ".agent-context/config.json is not valid JSON: $($_.Exception.Message)"
        $Config = $null
    }

    if ($null -ne $Config) {
        foreach ($Field in @("schema_version", "project_id", "project_name", "engine", "memory", "quality")) {
            if (-not ($Config.PSObject.Properties.Name -contains $Field)) {
                Add-Issue ".agent-context/config.json missing field '$Field'"
            }
        }

        Test-NonPlaceholder ([string]$Config.project_id) "project_id"
        Test-NonPlaceholder ([string]$Config.project_name) "project_name"

        if ($Config.engine) {
            foreach ($Field in @("name", "mode", "version", "source")) {
                if (-not ($Config.engine.PSObject.Properties.Name -contains $Field)) {
                    Add-Issue ".agent-context/config.json engine missing field '$Field'"
                }
            }

            if ($Config.engine.mode -ne "thin-launcher") {
                Add-Issue "engine.mode must be 'thin-launcher'"
            }
        }

        if ($Config.memory) {
            if (-not ($Config.memory.PSObject.Properties.Name -contains "source_paths")) {
                Add-Issue ".agent-context/config.json memory missing field 'source_paths'"
            }
            elseif ($Config.memory.source_paths.Count -eq 0) {
                Add-Issue "memory.source_paths must not be empty"
            }

            if (-not ($Config.memory.PSObject.Properties.Name -contains "local_index")) {
                Add-Issue ".agent-context/config.json memory missing field 'local_index'"
            }
            elseif ($Config.memory.local_index.git_tracked -ne $false) {
                Add-Issue "memory.local_index.git_tracked must be false"
            }
        }
    }
}

$MemoryDir = Join-Path $Root ".agent-context/memory-sources"
if (Test-Path -LiteralPath $MemoryDir -PathType Container) {
    $JsonlFiles = @(Get-ChildItem -LiteralPath $MemoryDir -Filter "*.jsonl" -File)
    foreach ($File in $JsonlFiles) {
        $Lines = @(Get-Content -LiteralPath $File.FullName -Encoding UTF8)
        for ($Index = 0; $Index -lt $Lines.Count; $Index++) {
            $Line = $Lines[$Index].Trim()
            if ([string]::IsNullOrWhiteSpace($Line)) {
                continue
            }

            Test-MemorySourceLine $File.FullName $Line ($Index + 1)
        }
    }
}

if ($Issues.Count -gt 0) {
    Write-Host "Agent project check failed:" -ForegroundColor Red
    foreach ($Issue in $Issues) {
        Write-Host (" - " + $Issue) -ForegroundColor Red
    }
    exit 1
}

Write-Host "Agent project check passed." -ForegroundColor Green
exit 0
