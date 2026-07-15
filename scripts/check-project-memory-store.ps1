$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$StoreRoot = Join-Path $Root "templates/project/docs/agent/memory-store"
$Issues = New-Object System.Collections.Generic.List[string]

function Add-Issue {
    param([string]$Message)
    $Issues.Add($Message) | Out-Null
}

function Test-StoreFile {
    param([string]$Name)
    $Path = Join-Path $StoreRoot $Name
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Add-Issue "Missing memory-store file: $Name"
    }
}

Test-StoreFile "README.md"
Test-StoreFile "memory-schema.json"
Test-StoreFile "memories.jsonl"
Test-StoreFile "retrieval-config.json"

$SchemaPath = Join-Path $StoreRoot "memory-schema.json"
if (Test-Path -LiteralPath $SchemaPath -PathType Leaf) {
    try {
        $Schema = Get-Content -LiteralPath $SchemaPath -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($RequiredField in @("id", "status", "type", "scope", "summary", "content", "source", "confidence", "last_verified")) {
            if ($Schema.required -notcontains $RequiredField) {
                Add-Issue "memory-schema.json does not require '$RequiredField'"
            }
        }
    }
    catch {
        Add-Issue "memory-schema.json is not valid JSON: $($_.Exception.Message)"
    }
}

$ConfigPath = Join-Path $StoreRoot "retrieval-config.json"
if (Test-Path -LiteralPath $ConfigPath -PathType Leaf) {
    try {
        $Config = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($Config.default_status_filter -notcontains "current") {
            Add-Issue "retrieval-config.json must include current in default_status_filter"
        }
        if ($Config.exclude_status_by_default -notcontains "stale") {
            Add-Issue "retrieval-config.json must exclude stale memories by default"
        }
    }
    catch {
        Add-Issue "retrieval-config.json is not valid JSON: $($_.Exception.Message)"
    }
}

$MemoriesPath = Join-Path $StoreRoot "memories.jsonl"
if (Test-Path -LiteralPath $MemoriesPath -PathType Leaf) {
    $LineNumber = 0
    Get-Content -LiteralPath $MemoriesPath -Encoding UTF8 | ForEach-Object {
        $LineNumber += 1
        if ([string]::IsNullOrWhiteSpace($_)) {
            return
        }

        try {
            $Record = $_ | ConvertFrom-Json
            foreach ($RequiredField in @("id", "status", "type", "scope", "summary", "content", "source", "confidence", "last_verified")) {
                if ($null -eq $Record.$RequiredField) {
                    Add-Issue "memories.jsonl line $LineNumber is missing '$RequiredField'"
                }
            }
        }
        catch {
            Add-Issue "memories.jsonl line $LineNumber is not valid JSON: $($_.Exception.Message)"
        }
    }
}

if ($Issues.Count -gt 0) {
    Write-Host "Project memory-store check failed:" -ForegroundColor Red
    foreach ($Issue in $Issues) {
        Write-Host " - $Issue" -ForegroundColor Red
    }
    exit 1
}

Write-Host "Project memory-store check passed." -ForegroundColor Green
exit 0
