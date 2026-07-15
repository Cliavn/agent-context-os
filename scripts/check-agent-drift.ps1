$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$AgentDir = Join-Path $Root "docs/agent"

if (-not (Test-Path -LiteralPath $AgentDir -PathType Container)) {
    Write-Host "Agent drift check skipped: docs/agent not found."
    exit 0
}

$CurrentTask = Join-Path $AgentDir "runtime/current-task.md"
$Issues = New-Object System.Collections.Generic.List[string]

function Add-Issue {
    param([string]$Message)
    $Issues.Add($Message) | Out-Null
}

function Get-GitChangedFiles {
    $Files = New-Object System.Collections.Generic.HashSet[string]

    $DiffArgs = @(
        @("diff", "--name-only", "HEAD", "--"),
        @("diff", "--cached", "--name-only", "--"),
        @("ls-files", "--others", "--exclude-standard")
    )

    foreach ($Args in $DiffArgs) {
        try {
            $Output = & git @Args 2>$null
            foreach ($Line in $Output) {
                if (-not [string]::IsNullOrWhiteSpace($Line)) {
                    $Files.Add($Line.Trim()) | Out-Null
                }
            }
        }
        catch {
            Add-Issue "Unable to inspect Git changed files with 'git $($Args -join ' ')': $($_.Exception.Message)"
            return $null
        }
    }

    return @($Files)
}

function Test-IsCodePath {
    param([string]$Path)

    if ($Path -like "docs/agent/*") {
        return $false
    }

    $Ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    $CodeExts = @(
        ".js", ".jsx", ".ts", ".tsx", ".py", ".cs", ".java", ".go", ".rs",
        ".php", ".rb", ".swift", ".kt", ".vue", ".svelte", ".css", ".scss",
        ".html", ".sql"
    )

    return $CodeExts -contains $Ext
}

$ChangedFiles = Get-GitChangedFiles

if ($null -eq $ChangedFiles) {
    Write-Host "Agent drift check failed:" -ForegroundColor Red
    foreach ($Issue in $Issues) {
        Write-Host " - $Issue" -ForegroundColor Red
    }
    exit 1
}

if ($ChangedFiles.Count -eq 0) {
    Write-Host "Agent drift check passed: no changed files."
    exit 0
}

$CodeChanged = $false
foreach ($File in $ChangedFiles) {
    if (Test-IsCodePath $File) {
        $CodeChanged = $true
        break
    }
}

if (-not $CodeChanged) {
    Write-Host "Agent drift check passed: no code-like changes."
    exit 0
}

if (-not (Test-Path -LiteralPath $CurrentTask -PathType Leaf)) {
    Add-Issue "Missing docs/agent/runtime/current-task.md for code-like changes."
}
else {
    $Content = Get-Content -LiteralPath $CurrentTask -Raw -Encoding UTF8

    foreach ($Required in @("change_level:", "memory_writeback:", "style_profile:", "verification:")) {
        if ($Content -notlike "*$Required*") {
            Add-Issue "current-task.md does not contain '$Required'"
        }
    }

    if ($Content -match "change_level:\s*<(S0|S1|S2|S3)") {
        Add-Issue "current-task.md still contains placeholder change_level."
    }
}

if ($Issues.Count -gt 0) {
    Write-Host "Agent drift check failed:" -ForegroundColor Red
    foreach ($Issue in $Issues) {
        Write-Host " - $Issue" -ForegroundColor Red
    }
    exit 1
}

Write-Host "Agent drift check passed." -ForegroundColor Green
exit 0
