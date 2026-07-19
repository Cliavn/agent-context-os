$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$AgentDir = Join-Path $Root "docs/agent"
$TemplateAgentDir = Join-Path $Root "templates/project/docs/agent"

if (-not (Test-Path -LiteralPath $AgentDir -PathType Container)) {
    if (Test-Path -LiteralPath $TemplateAgentDir -PathType Container) {
        Write-Host "Agent drift check skipped: blueprint template repository."
        exit 0
    }

    Write-Host "Agent drift check failed: docs/agent not found." -ForegroundColor Red
    exit 1
}

$CurrentTask = Join-Path $AgentDir "runtime/current-task.md"
$Issues = New-Object System.Collections.Generic.List[string]
$GitInspectionFailed = $false

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
            $script:GitInspectionFailed = $true
            return @()
        }
    }

    $Result = New-Object System.Collections.Generic.List[string]
    foreach ($File in $Files) {
        $Result.Add($File) | Out-Null
    }

    return $Result.ToArray()
}

function Test-IsCodePath {
    param([string]$Path)

    if ($Path -like "docs/agent/*") {
        return $false
    }

    $Ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    $Name = [System.IO.Path]::GetFileName($Path)
    $CodeExts = @(
        ".js", ".jsx", ".ts", ".tsx", ".mjs", ".cjs", ".mts", ".cts",
        ".py", ".cs", ".java", ".go", ".rs", ".php", ".rb", ".swift", ".kt",
        ".vue", ".svelte", ".css", ".scss", ".html", ".sql",
        ".ps1", ".sh", ".bat", ".cmd",
        ".json", ".yml", ".yaml", ".toml", ".xml"
    )
    $CodeNames = @("Dockerfile", "Makefile", "Rakefile", "Gemfile", "Jenkinsfile")

    return ($CodeExts -contains $Ext) -or ($CodeNames -contains $Name)
}

$ChangedFiles = @(Get-GitChangedFiles)

if ($GitInspectionFailed) {
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

    foreach ($Required in @("change_level:", "memory_writeback:", "style_profile:", "plan_ledger:", "workspace_mode:", "worktree_cleanup:", "strong_check:", "verification:")) {
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
