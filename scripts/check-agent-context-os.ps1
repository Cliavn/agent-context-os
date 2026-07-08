$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
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
    if ($Content -notlike "*$ExpectedText*") {
        Add-Issue "File '$RelativePath' does not reference '$ExpectedText'"
    }
}

$RequiredDirectories = @(
    "docs",
    "templates",
    "templates/project",
    "templates/project/docs/agent",
    "templates/project/docs/agent/workflows",
    "templates/project/docs/agent/checklists",
    "templates/project/docs/agent/modules",
    "templates/business",
    "templates/modules",
    "templates/reports",
    "examples",
    "scripts"
)

$RequiredFiles = @(
    "README.md",
    "AGENTS.md",
    "LICENSE",
    ".gitignore",
    "docs/00-system-overview.md",
    "docs/01-context-routing.md",
    "docs/02-business-modeling.md",
    "docs/03-architecture-boundaries.md",
    "docs/04-implementation-spec.md",
    "docs/05-quality-gates.md",
    "docs/06-known-issues-system.md",
    "docs/07-token-budget.md",
    "docs/08-multi-agent-policy.md",
    "templates/project/AGENTS.md",
    "templates/project/docs/agent/00-index.md",
    "templates/project/docs/agent/01-project-overview.md",
    "templates/project/docs/agent/02-architecture.md",
    "templates/project/docs/agent/03-tech-stack.md",
    "templates/project/docs/agent/04-decisions.md",
    "templates/project/docs/agent/quality.md",
    "templates/project/docs/agent/review.md",
    "templates/project/docs/agent/task-report-template.md",
    "templates/project/docs/agent/modules/_template.md",
    "templates/project/docs/agent/workflows/bug-fix.md",
    "templates/project/docs/agent/workflows/new-feature.md",
    "templates/project/docs/agent/workflows/refactor.md",
    "templates/project/docs/agent/workflows/ui-change.md",
    "templates/project/docs/agent/workflows/version-control.md",
    "templates/project/docs/agent/checklists/bug-fix-checklist.md",
    "templates/project/docs/agent/checklists/new-feature-checklist.md",
    "templates/project/docs/agent/checklists/refactor-checklist.md",
    "templates/project/docs/agent/checklists/ui-change-checklist.md",
    "templates/project/docs/agent/checklists/version-control-checklist.md",
    "templates/business/module-overview.md",
    "templates/business/business-flow.md",
    "templates/business/field-rules.md",
    "templates/business/state-machine.md",
    "templates/business/api-contract.md",
    "templates/business/edge-cases.md",
    "templates/business/acceptance.md",
    "templates/modules/module-card.md",
    "templates/reports/implementation-spec.md",
    "templates/reports/task-report.md",
    "templates/reports/known-issue.md",
    "scripts/check-agent-context-os.ps1"
)

foreach ($Directory in $RequiredDirectories) {
    Test-RequiredDirectory $Directory
}

foreach ($File in $RequiredFiles) {
    Test-RequiredFile $File
}

Test-ContainsText "README.md" "Agent Context OS"
Test-ContainsText "AGENTS.md" "Agent Context OS"
Test-ContainsText "docs/01-context-routing.md" "Token"
Test-ContainsText "docs/02-business-modeling.md" "Agent"
Test-ContainsText "docs/07-token-budget.md" "Agent"
Test-ContainsText "docs/08-multi-agent-policy.md" "Agent"
Test-ContainsText "templates/project/AGENTS.md" "docs/agent/00-index.md"
Test-ContainsText "templates/project/docs/agent/00-index.md" "workflow"
Test-ContainsText "templates/business/field-rules.md" "field_name"
Test-ContainsText "templates/reports/implementation-spec.md" "## 9."

if ($Issues.Count -gt 0) {
    Write-Host "Agent Context OS check failed:" -ForegroundColor Red
    foreach ($Issue in $Issues) {
        Write-Host " - $Issue" -ForegroundColor Red
    }
    exit 1
}

Write-Host "Agent Context OS check passed." -ForegroundColor Green
exit 0
