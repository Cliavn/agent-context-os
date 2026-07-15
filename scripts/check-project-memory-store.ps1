param(
    [string]$StoreRoot
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$ProjectStoreRoot = Join-Path $Root "docs/agent/memory-store"
$TemplateStoreRoot = Join-Path $Root "templates/project/docs/agent/memory-store"

if ([string]::IsNullOrWhiteSpace($StoreRoot)) {
    if (Test-Path -LiteralPath $ProjectStoreRoot -PathType Container) {
        $StoreRoot = $ProjectStoreRoot
    }
    else {
        $StoreRoot = $TemplateStoreRoot
    }
}
elseif (-not [System.IO.Path]::IsPathRooted($StoreRoot)) {
    $StoreRoot = Join-Path $Root $StoreRoot
}

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

function Test-ObjectProperties {
    param(
        [object]$Object,
        [string[]]$AllowedProperties,
        [string]$Path
    )

    foreach ($Property in $Object.PSObject.Properties.Name) {
        if ($AllowedProperties -notcontains $Property) {
            Add-Issue "$Path contains unexpected property '$Property'"
        }
    }
}

function Test-RequiredProperty {
    param(
        [object]$Object,
        [string]$Name,
        [string]$Path
    )

    if ($null -eq $Object.PSObject.Properties[$Name] -or $null -eq $Object.$Name) {
        Add-Issue "$Path is missing '$Name'"
        return $false
    }

    return $true
}

function Test-NonEmptyString {
    param(
        [object]$Value,
        [string]$Path
    )

    if ($Value -isnot [string] -or [string]::IsNullOrWhiteSpace($Value)) {
        Add-Issue "$Path must be a non-empty string"
    }
}

function Test-StringEnum {
    param(
        [object]$Value,
        [string[]]$AllowedValues,
        [string]$Path
    )

    if ($Value -isnot [string] -or $AllowedValues -notcontains $Value) {
        Add-Issue "$Path must be one of: $($AllowedValues -join ', ')"
    }
}

function Test-StringPattern {
    param(
        [object]$Value,
        [string]$Pattern,
        [string]$Path
    )

    if ($Value -isnot [string] -or $Value -notmatch $Pattern) {
        Add-Issue "$Path must match pattern $Pattern"
    }
}

function Test-StringArray {
    param(
        [object]$Value,
        [string]$Path,
        [bool]$RequireItems
    )

    if ($Value -isnot [array]) {
        Add-Issue "$Path must be an array"
        return
    }

    if ($RequireItems -and $Value.Count -lt 1) {
        Add-Issue "$Path must contain at least one item"
        return
    }

    for ($Index = 0; $Index -lt $Value.Count; $Index += 1) {
        Test-NonEmptyString $Value[$Index] "$Path[$Index]"
    }
}

function Test-MemoryRecord {
    param(
        [object]$Record,
        [int]$LineNumber
    )

    $RecordPath = "memories.jsonl line $LineNumber"
    $RequiredFields = @("id", "status", "type", "scope", "summary", "content", "source", "confidence", "last_verified")
    $AllowedFields = @("id", "status", "type", "scope", "summary", "content", "source", "evidence", "confidence", "last_verified", "tags", "replaces", "replaced_by")
    $StatusValues = @("current", "draft", "assumption", "deprecated", "stale")
    $TypeValues = @("project_fact", "business_rule", "interaction_rule", "architecture_rule", "implementation_note", "known_issue", "decision", "open_question")
    $SourceKindValues = @("user_confirmed", "code", "test", "doc", "decision", "task_report", "issue", "conversation_summary")
    $ConfidenceValues = @("high", "medium", "low")

    Test-ObjectProperties $Record $AllowedFields $RecordPath

    foreach ($RequiredField in $RequiredFields) {
        [void](Test-RequiredProperty $Record $RequiredField $RecordPath)
    }

    Test-StringPattern $Record.id "^mem-[0-9]{8}-[0-9]{3}$" "$RecordPath.id"
    Test-StringEnum $Record.status $StatusValues "$RecordPath.status"
    Test-StringEnum $Record.type $TypeValues "$RecordPath.type"
    Test-StringArray $Record.scope "$RecordPath.scope" $true
    Test-NonEmptyString $Record.summary "$RecordPath.summary"
    Test-NonEmptyString $Record.content "$RecordPath.content"
    Test-StringEnum $Record.confidence $ConfidenceValues "$RecordPath.confidence"
    Test-StringPattern $Record.last_verified "^[0-9]{4}-[0-9]{2}-[0-9]{2}$" "$RecordPath.last_verified"

    if ($null -ne $Record.source) {
        if ($Record.source -isnot [pscustomobject]) {
            Add-Issue "$RecordPath.source must be an object"
        }
        else {
            Test-ObjectProperties $Record.source @("kind", "ref", "date") "$RecordPath.source"
            foreach ($RequiredSourceField in @("kind", "ref", "date")) {
                [void](Test-RequiredProperty $Record.source $RequiredSourceField "$RecordPath.source")
            }
            Test-StringEnum $Record.source.kind $SourceKindValues "$RecordPath.source.kind"
            Test-NonEmptyString $Record.source.ref "$RecordPath.source.ref"
            Test-StringPattern $Record.source.date "^[0-9]{4}-[0-9]{2}-[0-9]{2}$" "$RecordPath.source.date"
        }
    }

    if ($null -ne $Record.evidence) {
        Test-StringArray $Record.evidence "$RecordPath.evidence" $false
    }
    if ($null -ne $Record.tags) {
        Test-StringArray $Record.tags "$RecordPath.tags" $false
    }
    if ($null -ne $Record.replaces) {
        Test-StringArray $Record.replaces "$RecordPath.replaces" $false
    }
    if ($null -ne $Record.replaced_by) {
        Test-NonEmptyString $Record.replaced_by "$RecordPath.replaced_by"
    }
}

if (-not (Test-Path -LiteralPath $StoreRoot -PathType Container)) {
    Add-Issue "Missing memory-store directory: $StoreRoot"
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
            Test-MemoryRecord $Record $LineNumber
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
