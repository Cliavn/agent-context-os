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
    if (-not $Content.Contains($ExpectedText)) {
        Add-Issue "File '$RelativePath' does not reference '$ExpectedText'"
    }
}

function Invoke-CheckScript {
    param(
        [string]$RelativePath,
        [string[]]$Arguments = @()
    )

    $Path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return
    }

    $Output = & powershell -NoProfile -ExecutionPolicy Bypass -File $Path @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        Add-Issue "Check script failed: $RelativePath"
        foreach ($Line in $Output) {
            Add-Issue "  $Line"
        }
    }
}

function Test-FilesEqual {
    param(
        [string]$ExpectedRelativePath,
        [string]$ActualRelativePath
    )

    $ExpectedPath = Join-Path $Root $ExpectedRelativePath
    $ActualPath = Join-Path $Root $ActualRelativePath
    if (-not (Test-Path -LiteralPath $ExpectedPath -PathType Leaf) -or -not (Test-Path -LiteralPath $ActualPath -PathType Leaf)) {
        return
    }

    $ExpectedContent = Get-Content -LiteralPath $ExpectedPath -Raw -Encoding UTF8
    $ActualContent = Get-Content -LiteralPath $ActualPath -Raw -Encoding UTF8
    if ($ExpectedContent -ne $ActualContent) {
        Add-Issue "File '$ActualRelativePath' must match '$ExpectedRelativePath'"
    }
}

$RequiredDirectories = @(
    "docs",
    "templates",
    "templates/project",
    "templates/project/scripts",
    "templates/project/docs/agent",
    "templates/project/docs/agent/workflows",
    "templates/project/docs/agent/checklists",
    "templates/project/docs/agent/modules",
    "templates/project/docs/agent/memory-store",
    "templates/project/docs/agent/plans",
    "templates/project/docs/agent/runtime",
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
    ".gitattributes",
    "docs/00-system-overview.md",
    "docs/01-context-routing.md",
    "docs/02-business-modeling.md",
    "docs/03-architecture-boundaries.md",
    "docs/04-implementation-spec.md",
    "docs/05-quality-gates.md",
    "docs/06-known-issues-system.md",
    "docs/07-token-budget.md",
    "docs/08-multi-agent-policy.md",
    "docs/09-project-memory.md",
    "docs/10-progressive-adoption.md",
    "docs/11-plan-intake.md",
    "docs/12-execution-gates.md",
    "docs/13-project-style-profile.md",
    "docs/14-retrieval-memory-store.md",
    "docs/15-release-readiness-review.md",
    "docs/16-plan-execution-ledger.md",
    "templates/project/.gitignore",
    "templates/project/.gitattributes",
    "templates/project/AGENTS.md",
    "templates/project/docs/agent/00-index.md",
    "templates/project/docs/agent/01-project-overview.md",
    "templates/project/docs/agent/style-profile.md",
    "templates/project/docs/agent/adoption.md",
    "templates/project/docs/agent/intake.md",
    "templates/project/docs/agent/change-levels.md",
    "templates/project/docs/agent/memory.md",
    "templates/project/docs/agent/memory-store/README.md",
    "templates/project/docs/agent/memory-store/memory-schema.json",
    "templates/project/docs/agent/memory-store/memories.jsonl",
    "templates/project/docs/agent/memory-store/retrieval-config.json",
    "templates/project/docs/agent/plans/README.md",
    "templates/project/docs/agent/plans/_template.md",
    "templates/project/scripts/check-project-memory-store.ps1",
    "templates/project/scripts/check-agent-drift.ps1",
    "templates/project/docs/agent/legacy-docs.md",
    "templates/project/docs/agent/02-architecture.md",
    "templates/project/docs/agent/03-tech-stack.md",
    "templates/project/docs/agent/04-decisions.md",
    "templates/project/docs/agent/quality.md",
    "templates/project/docs/agent/review.md",
    "templates/project/docs/agent/task-report-template.md",
    "templates/project/docs/agent/modules/_template.md",
    "templates/project/docs/agent/runtime/current-task.md",
    "templates/project/docs/agent/workflows/bug-fix.md",
    "templates/project/docs/agent/workflows/new-feature.md",
    "templates/project/docs/agent/workflows/refactor.md",
    "templates/project/docs/agent/workflows/ui-change.md",
    "templates/project/docs/agent/workflows/version-control.md",
    "templates/project/docs/agent/workflows/progressive-adoption.md",
    "templates/project/docs/agent/workflows/plan-intake.md",
    "templates/project/docs/agent/workflows/execution-gate.md",
    "templates/project/docs/agent/checklists/adoption-checklist.md",
    "templates/project/docs/agent/checklists/plan-intake-checklist.md",
    "templates/project/docs/agent/checklists/execution-gate-checklist.md",
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
    "templates/reports/plan-intake-report.md",
    "templates/reports/known-issue.md",
    "scripts/check-agent-context-os.ps1",
    "scripts/check-project-memory-store.ps1",
    "scripts/check-agent-drift.ps1"
)

foreach ($Directory in $RequiredDirectories) {
    Test-RequiredDirectory $Directory
}

foreach ($File in $RequiredFiles) {
    Test-RequiredFile $File
}

Test-ContainsText "README.md" "Agent Context OS"
Test-ContainsText "AGENTS.md" "Agent Context OS"
Test-ContainsText ".gitattributes" "*.ps1 text eol=crlf"
Test-ContainsText "docs/01-context-routing.md" "Token"
Test-ContainsText "docs/02-business-modeling.md" "Agent"
Test-ContainsText "docs/07-token-budget.md" "Agent"
Test-ContainsText "docs/08-multi-agent-policy.md" "Agent"
Test-ContainsText "docs/09-project-memory.md" "assumption"
Test-ContainsText "docs/10-progressive-adoption.md" "progressive"
Test-ContainsText "docs/11-plan-intake.md" "proposed"
Test-ContainsText "docs/11-plan-intake.md" "discussion_only"
Test-ContainsText "docs/11-plan-intake.md" "draft_record"
Test-ContainsText "docs/12-execution-gates.md" "S0"
Test-ContainsText "docs/12-execution-gates.md" "git_commit"
Test-ContainsText "docs/13-project-style-profile.md" "style-profile.md"
Test-ContainsText 'docs/14-retrieval-memory-store.md' 'memory-store'
Test-ContainsText 'docs/15-release-readiness-review.md' 'RR-001'
Test-ContainsText 'docs/16-plan-execution-ledger.md' 'confirmed'
Test-ContainsText 'docs/16-plan-execution-ledger.md' 'plan-id'
Test-ContainsText "templates/project/.gitattributes" "*.ps1 text eol=crlf"
Test-ContainsText "templates/project/.gitignore" ".env"
Test-ContainsText "templates/project/AGENTS.md" "docs/agent/00-index.md"
Test-ContainsText "templates/project/AGENTS.md" "docs/agent/style-profile.md"
Test-ContainsText "templates/project/AGENTS.md" "docs/agent/memory.md"
Test-ContainsText 'templates/project/AGENTS.md' 'docs/agent/memory-store/README.md'
Test-ContainsText "templates/project/AGENTS.md" "docs/agent/adoption.md"
Test-ContainsText "templates/project/AGENTS.md" "docs/agent/intake.md"
Test-ContainsText "templates/project/AGENTS.md" "S0"
Test-ContainsText "templates/project/AGENTS.md" "Git"
Test-ContainsText "templates/project/AGENTS.md" "discussion_only"
Test-ContainsText "templates/project/AGENTS.md" "docs/agent/plans"
Test-ContainsText "templates/project/docs/agent/00-index.md" "workflow"
Test-ContainsText "templates/project/docs/agent/00-index.md" "plans/README.md"
Test-ContainsText "templates/project/docs/agent/style-profile.md" "current"
Test-ContainsText "templates/project/docs/agent/adoption.md" "progressive"
Test-ContainsText "templates/project/docs/agent/intake.md" "plan-id"
Test-ContainsText "templates/project/docs/agent/change-levels.md" "S0"
Test-ContainsText "templates/project/docs/agent/memory.md" "assumption"
Test-ContainsText 'templates/project/docs/agent/memory-store/README.md' 'memories.jsonl'
Test-ContainsText 'templates/project/docs/agent/memory-store/memory-schema.json' 'last_verified'
Test-ContainsText 'templates/project/docs/agent/memory-store/memories.jsonl' 'mem-20260101-001'
Test-ContainsText 'templates/project/docs/agent/memory-store/retrieval-config.json' 'default_status_filter'
Test-ContainsText 'templates/project/docs/agent/plans/README.md' 'confirmed'
Test-ContainsText 'templates/project/docs/agent/plans/_template.md' 'plan-id'
Test-ContainsText 'templates/project/docs/agent/plans/_template.md' 'T1'
Test-ContainsText "templates/project/docs/agent/legacy-docs.md" "indexed"
Test-ContainsText "templates/project/docs/agent/runtime/current-task.md" "change_level"
Test-ContainsText 'templates/project/docs/agent/runtime/current-task.md' 'retrieval_memory'
Test-ContainsText "templates/project/docs/agent/runtime/current-task.md" "style_profile"
Test-ContainsText "templates/project/docs/agent/runtime/current-task.md" "plan_ledger"
Test-ContainsText 'templates/project/docs/agent/runtime/current-task.md' 'git_commit'
Test-ContainsText 'templates/project/docs/agent/runtime/current-task.md' 'pushed'
Test-ContainsText "templates/project/docs/agent/workflows/progressive-adoption.md" "Agent Context Engine"
Test-ContainsText "templates/project/docs/agent/workflows/plan-intake.md" "current"
Test-ContainsText "templates/project/docs/agent/workflows/plan-intake.md" "discussion_only"
Test-ContainsText "templates/project/docs/agent/workflows/plan-intake.md" "plans/<plan-id>.md"
Test-ContainsText "templates/project/docs/agent/workflows/execution-gate.md" "S0"
Test-ContainsText "templates/project/docs/agent/workflows/execution-gate.md" "discussion_only"
Test-ContainsText "templates/project/docs/agent/workflows/execution-gate.md" "confirmed"
Test-ContainsText "templates/project/docs/agent/checklists/adoption-checklist.md" "legacy-docs.md"
Test-ContainsText "templates/project/docs/agent/checklists/plan-intake-checklist.md" "conflict"
Test-ContainsText "templates/project/docs/agent/checklists/plan-intake-checklist.md" "discussion_only"
Test-ContainsText "templates/project/docs/agent/checklists/plan-intake-checklist.md" "plans/<plan-id>.md"
Test-ContainsText "templates/project/docs/agent/checklists/execution-gate-checklist.md" "current-task.md"
Test-ContainsText "templates/project/docs/agent/checklists/version-control-checklist.md" "Git"
Test-ContainsText "templates/business/field-rules.md" "field_name"
Test-ContainsText "templates/reports/implementation-spec.md" "docs/agent/memory.md"
Test-ContainsText "templates/reports/implementation-spec.md" "plan-id.md"
Test-ContainsText "templates/reports/task-report.md" "docs/agent/memory.md"
Test-ContainsText 'templates/reports/task-report.md' 'memory-store'
Test-ContainsText "templates/reports/task-report.md" "Git"
Test-ContainsText "templates/project/docs/agent/task-report-template.md" "pushed"
Test-ContainsText "templates/reports/plan-intake-report.md" "proposed"
Test-ContainsText "templates/reports/plan-intake-report.md" "T1"
Test-ContainsText "scripts/check-agent-drift.ps1" "change_level:"
Test-ContainsText "scripts/check-agent-drift.ps1" "plan_ledger:"
Test-ContainsText 'scripts/check-project-memory-store.ps1' 'memory-schema.json'
Test-ContainsText "templates/project/scripts/check-agent-drift.ps1" "change_level:"
Test-ContainsText "templates/project/scripts/check-agent-drift.ps1" "plan_ledger:"
Test-ContainsText 'templates/project/scripts/check-project-memory-store.ps1' 'memory-schema.json'
Test-FilesEqual "scripts/check-agent-drift.ps1" "templates/project/scripts/check-agent-drift.ps1"
Test-FilesEqual "scripts/check-project-memory-store.ps1" "templates/project/scripts/check-project-memory-store.ps1"

Invoke-CheckScript "scripts/check-project-memory-store.ps1" @("-StoreRoot", "templates/project/docs/agent/memory-store")

if ($Issues.Count -gt 0) {
    Write-Host 'Agent Context OS check failed:' -ForegroundColor Red
    foreach ($Issue in $Issues) {
        Write-Host (' - ' + $Issue) -ForegroundColor Red
    }
    exit 1
}

Write-Host 'Agent Context OS check passed.' -ForegroundColor Green
exit 0
