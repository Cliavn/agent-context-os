[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$AllowPlaceholders
)

$ErrorActionPreference = "Stop"
$Issues = New-Object System.Collections.Generic.List[string]
$SensitivePatterns = @(
    "(?i)\b(api[_-]?key|token|access[_-]?token|refresh[_-]?token|secret|password|passwd|pwd|credential|private[_-]?key|cookie|session[_-]?id)\b",
    "\u8d26\u53f7",
    "\u5bc6\u7801",
    "\u5bc6\u94a5",
    "\u51ed\u636e",
    "\u79c1\u94a5",
    "\u8bbf\u95ee\u4ee4\u724c",
    "\u5237\u65b0\u4ee4\u724c",
    "\u771f\u5b9e\u9690\u79c1"
)

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

    if (-not $AllowPlaceholders -and ($Value -match "<[^>]+>" -or $Value -match "YYYY")) {
        Add-Issue "$Field still contains a placeholder"
    }
}

function Test-NoPlaceholderObject {
    param(
        [object]$Value,
        [string]$Field
    )

    if ($null -eq $Value) {
        return
    }

    if ($Value -is [string]) {
        Test-NonPlaceholder $Value $Field
        return
    }

    if ($Value -is [System.Array]) {
        for ($Index = 0; $Index -lt $Value.Count; $Index++) {
            Test-NoPlaceholderObject $Value[$Index] "$Field[$Index]"
        }
        return
    }

    if ($Value -is [System.Management.Automation.PSCustomObject]) {
        foreach ($Property in $Value.PSObject.Properties) {
            Test-NoPlaceholderObject $Property.Value "$Field.$($Property.Name)"
        }
    }
}

function Test-NoSensitiveText {
    param(
        [string]$Value,
        [string]$Field
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    foreach ($Pattern in $SensitivePatterns) {
        if ($Value -match $Pattern) {
            Add-Issue "$Field contains sensitive marker '$($Matches[0])'"
            return
        }
    }
}

function Test-NoSensitiveObject {
    param(
        [object]$Value,
        [string]$Field
    )

    if ($null -eq $Value) {
        return
    }

    if ($Value -is [string]) {
        Test-NoSensitiveText $Value $Field
        return
    }

    if ($Value -is [System.Array]) {
        for ($Index = 0; $Index -lt $Value.Count; $Index++) {
            Test-NoSensitiveObject $Value[$Index] "$Field[$Index]"
        }
        return
    }

    if ($Value -is [System.Management.Automation.PSCustomObject]) {
        foreach ($Property in $Value.PSObject.Properties) {
            Test-NoSensitiveObject $Property.Value "$Field.$($Property.Name)"
        }
    }
}

function Test-DateString {
    param(
        [string]$Value,
        [string]$Field
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        Add-Issue "$Field must not be empty"
        return
    }

    if ($AllowPlaceholders -and $Value -match "YYYY") {
        return
    }

    if ($Value -notmatch "^\d{4}-\d{2}-\d{2}$") {
        Add-Issue "$Field must use YYYY-MM-DD"
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

    Test-NoPlaceholderObject $Record "$Path line $LineNumber"
    Test-NoSensitiveObject $Record "$Path line $LineNumber"

    if ($Record.status -and @("current", "draft", "assumption", "stale", "deprecated") -notcontains $Record.status) {
        Add-Issue "$Path line $LineNumber has invalid status '$($Record.status)'"
    }

    if ($Record.confidence -and @("high", "medium", "low") -notcontains $Record.confidence) {
        Add-Issue "$Path line $LineNumber has invalid confidence '$($Record.confidence)'"
    }

    if ($Record.scope -and ($Record.scope -isnot [System.Array] -or $Record.scope.Count -eq 0)) {
        Add-Issue "$Path line $LineNumber scope must be a non-empty array"
    }

    if ($Record.source) {
        foreach ($Field in @("kind", "ref", "date")) {
            if (-not ($Record.source.PSObject.Properties.Name -contains $Field)) {
                Add-Issue "$Path line $LineNumber source missing field '$Field'"
            }
        }

        if ($Record.source.date) {
            Test-DateString ([string]$Record.source.date) "$Path line $LineNumber source.date"
        }
    }

    if ($Record.last_verified) {
        Test-DateString ([string]$Record.last_verified) "$Path line $LineNumber last_verified"
    }
}

function Get-MemorySourceFiles {
    param([object]$SourcePaths)

    $Files = New-Object System.Collections.Generic.List[object]
    $Seen = @{}

    foreach ($SourcePath in @($SourcePaths)) {
        if ([string]::IsNullOrWhiteSpace([string]$SourcePath)) {
            continue
        }

        $FullPattern = Join-Path $Root ([string]$SourcePath)
        $Matches = @(Get-ChildItem -Path $FullPattern -File -ErrorAction SilentlyContinue)

        foreach ($File in $Matches) {
            if (-not $Seen.ContainsKey($File.FullName)) {
                $Seen[$File.FullName] = $true
                $Files.Add($File) | Out-Null
            }
        }
    }

    return $Files.ToArray()
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

            Test-NonPlaceholder ([string]$Config.engine.name) "engine.name"
            Test-NonPlaceholder ([string]$Config.engine.mode) "engine.mode"
            Test-NonPlaceholder ([string]$Config.engine.version) "engine.version"
            Test-NonPlaceholder ([string]$Config.engine.source) "engine.source"
        }

        if ($Config.memory) {
            if (-not ($Config.memory.PSObject.Properties.Name -contains "source_paths")) {
                Add-Issue ".agent-context/config.json memory missing field 'source_paths'"
            }
            elseif ($Config.memory.source_paths.Count -eq 0) {
                Add-Issue "memory.source_paths must not be empty"
            }
            else {
                foreach ($SourcePath in @($Config.memory.source_paths)) {
                    Test-NonPlaceholder ([string]$SourcePath) "memory.source_paths"

                    if ([string]$SourcePath -notlike "*.jsonl") {
                        Add-Issue "memory.source_paths entries must target JSONL files"
                    }

                    if ([string]$SourcePath -like "*_example*") {
                        Add-Issue "memory.source_paths must not include example files"
                    }
                }
            }

            if (-not ($Config.memory.PSObject.Properties.Name -contains "local_index")) {
                Add-Issue ".agent-context/config.json memory missing field 'local_index'"
            }
            elseif ($Config.memory.local_index.git_tracked -ne $false) {
                Add-Issue "memory.local_index.git_tracked must be false"
            }

            if ($Config.memory.local_index) {
                foreach ($Field in @("provider", "path", "git_tracked")) {
                    if (-not ($Config.memory.local_index.PSObject.Properties.Name -contains $Field)) {
                        Add-Issue ".agent-context/config.json memory.local_index missing field '$Field'"
                    }
                }

                Test-NonPlaceholder ([string]$Config.memory.local_index.provider) "memory.local_index.provider"
                Test-NonPlaceholder ([string]$Config.memory.local_index.path) "memory.local_index.path"
            }
        }

        if ($Config.quality) {
            foreach ($Field in @("check_command", "validation_commands")) {
                if (-not ($Config.quality.PSObject.Properties.Name -contains $Field)) {
                    Add-Issue ".agent-context/config.json quality missing field '$Field'"
                }
            }

            Test-NonPlaceholder ([string]$Config.quality.check_command) "quality.check_command"

            if ($Config.quality.validation_commands.Count -eq 0) {
                Add-Issue "quality.validation_commands must not be empty"
            }
            else {
                foreach ($Command in @($Config.quality.validation_commands)) {
                    Test-NonPlaceholder ([string]$Command) "quality.validation_commands"
                }
            }
        }
    }
}

$MemoryDir = Join-Path $Root ".agent-context/memory-sources"
if (Test-Path -LiteralPath $MemoryDir -PathType Container) {
    $JsonlFiles = @()
    if ($Config -and $Config.memory -and $Config.memory.source_paths) {
        $JsonlFiles = @(Get-MemorySourceFiles $Config.memory.source_paths)
    }

    if ($JsonlFiles.Count -eq 0 -and -not $AllowPlaceholders) {
        Add-Issue "memory.source_paths did not match any JSONL memory source"
    }

    foreach ($File in $JsonlFiles) {
        if ($File.Name.StartsWith("_")) {
            Add-Issue "$($File.FullName) is an example or reserved file and must not be an active memory source"
            continue
        }

        $Lines = @(Get-Content -LiteralPath $File.FullName -Encoding UTF8)
        $NonEmptyLineCount = 0
        for ($Index = 0; $Index -lt $Lines.Count; $Index++) {
            $Line = $Lines[$Index].Trim()
            if ([string]::IsNullOrWhiteSpace($Line)) {
                continue
            }

            $NonEmptyLineCount++
            Test-MemorySourceLine $File.FullName $Line ($Index + 1)
        }

        if ($NonEmptyLineCount -eq 0 -and -not $AllowPlaceholders) {
            Add-Issue "$($File.FullName) must contain at least one memory record"
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
