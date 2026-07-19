[CmdletBinding()]
param(
    [switch]$Prune,
    [switch]$AllowNested
)

$ErrorActionPreference = "Stop"
$Issues = New-Object System.Collections.Generic.List[string]

function Add-Issue {
    param([string]$Message)
    $Issues.Add($Message) | Out-Null
}

function Normalize-PathForCompare {
    param([string]$Path)

    return ([System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/') -replace '/', '\')
}

function Get-WorktreeEntries {
    $Output = & git worktree list --porcelain 2>&1
    if ($LASTEXITCODE -ne 0) {
        Add-Issue "Unable to list Git worktrees: $($Output -join ' ')"
        return @()
    }

    $Entries = New-Object System.Collections.Generic.List[object]
    $Current = $null

    foreach ($Line in $Output) {
        if ($Line -like "worktree *") {
            if ($null -ne $Current) {
                $Entries.Add([pscustomobject]$Current) | Out-Null
            }

            $Current = [ordered]@{
                Path = $Line.Substring(9)
                Branch = ""
                Detached = $false
                Prunable = $false
                PrunableReason = ""
            }
            continue
        }

        if ($null -eq $Current) {
            continue
        }

        if ($Line -like "branch *") {
            $Current.Branch = $Line.Substring(7)
        }
        elseif ($Line -eq "detached") {
            $Current.Detached = $true
        }
        elseif ($Line -like "prunable*") {
            $Current.Prunable = $true
            $Current.PrunableReason = $Line.Substring(8).Trim()
        }
    }

    if ($null -ne $Current) {
        $Entries.Add([pscustomobject]$Current) | Out-Null
    }

    return $Entries.ToArray()
}

$RootOutput = & git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($RootOutput)) {
    Write-Host "Agent worktree check failed: current directory is not a Git repository." -ForegroundColor Red
    exit 1
}

$Root = Normalize-PathForCompare $RootOutput.Trim()

if ($Prune) {
    $PruneOutput = & git worktree prune 2>&1
    if ($LASTEXITCODE -ne 0) {
        Add-Issue "Unable to prune Git worktrees: $($PruneOutput -join ' ')"
    }
}

$Entries = @(Get-WorktreeEntries)

if ($Entries.Count -eq 0) {
    Add-Issue "Git returned no worktrees."
}

foreach ($Entry in $Entries) {
    try {
        $EntryPath = Normalize-PathForCompare $Entry.Path
    }
    catch {
        Add-Issue "Invalid worktree path '$($Entry.Path)': $($_.Exception.Message)"
        continue
    }

    $IsRoot = [string]::Equals($EntryPath, $Root, [System.StringComparison]::OrdinalIgnoreCase)
    $IsNested = (-not $IsRoot) -and $EntryPath.StartsWith($Root + "\", [System.StringComparison]::OrdinalIgnoreCase)

    if ($IsNested -and -not $AllowNested) {
        Add-Issue "Worktree is nested inside the repository root: $($Entry.Path)"
    }

    if ($Entry.Prunable) {
        $Reason = $Entry.PrunableReason
        if ([string]::IsNullOrWhiteSpace($Reason)) {
            $Reason = "no reason provided"
        }
        Add-Issue "Prunable worktree remains: $($Entry.Path) ($Reason)"
    }
}

if ($Issues.Count -gt 0) {
    Write-Host "Agent worktree check failed:" -ForegroundColor Red
    foreach ($Issue in $Issues) {
        Write-Host (" - " + $Issue) -ForegroundColor Red
    }
    exit 1
}

Write-Host "Agent worktree check passed: $($Entries.Count) worktree(s) inspected." -ForegroundColor Green
exit 0
