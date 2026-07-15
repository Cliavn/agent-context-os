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

$MemoryIdPattern = "^mem-[0-9]{8}-[0-9]{3}$"
$DatePattern = "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"
$RequiredRecordFields = @("id", "status", "type", "scope", "summary", "content", "source", "confidence", "last_verified")
$AllowedRecordFields = @("id", "status", "type", "scope", "summary", "content", "source", "evidence", "confidence", "last_verified", "tags", "replaces", "replaced_by")
$StatusValues = @("current", "draft", "assumption", "deprecated", "stale")
$TypeValues = @("project_fact", "business_rule", "interaction_rule", "architecture_rule", "implementation_note", "known_issue", "decision", "open_question")
$SourceKindValues = @("user_confirmed", "code", "test", "doc", "decision", "task_report", "issue", "conversation_summary")
$ConfidenceValues = @("high", "medium", "low")
$ForbiddenContentValues = @()

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

function Test-DateString {
    param(
        [object]$Value,
        [string]$Path
    )

    Test-StringPattern $Value $DatePattern $Path
    if ($Value -isnot [string] -or $Value -notmatch $DatePattern) {
        return
    }

    $ParsedDate = [datetime]::MinValue
    $IsValidDate = [datetime]::TryParseExact(
        $Value,
        "yyyy-MM-dd",
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::None,
        [ref]$ParsedDate
    )
    if (-not $IsValidDate) {
        Add-Issue "$Path must be a valid calendar date"
    }
}

function Test-MemoryId {
    param(
        [object]$Value,
        [string]$Path
    )

    Test-StringPattern $Value $MemoryIdPattern $Path
    if ($Value -isnot [string] -or $Value -notmatch "^mem-([0-9]{8})-[0-9]{3}$") {
        return
    }

    $ParsedDate = [datetime]::MinValue
    $IsValidDate = [datetime]::TryParseExact(
        $Matches[1],
        "yyyyMMdd",
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::None,
        [ref]$ParsedDate
    )
    if (-not $IsValidDate) {
        Add-Issue "$Path must contain a valid YYYYMMDD date"
    }
}

function Test-Boolean {
    param(
        [object]$Value,
        [string]$Path
    )

    if ($Value -isnot [bool]) {
        Add-Issue "$Path must be a boolean"
    }
}

function Test-PositiveNumber {
    param(
        [object]$Value,
        [string]$Path
    )

    $IsNumber = $Value -is [int] -or $Value -is [long] -or $Value -is [double] -or $Value -is [decimal]
    if (-not $IsNumber -or $Value -le 0) {
        Add-Issue "$Path must be a positive number"
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

function Test-StringEnumArray {
    param(
        [object]$Value,
        [string[]]$AllowedValues,
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
        Test-StringEnum $Value[$Index] $AllowedValues "$Path[$Index]"
    }
}

function Test-ContainsAll {
    param(
        [object]$ActualValues,
        [string[]]$ExpectedValues,
        [string]$Path
    )

    foreach ($ExpectedValue in $ExpectedValues) {
        if ($ActualValues -notcontains $ExpectedValue) {
            Add-Issue "$Path must include '$ExpectedValue'"
        }
    }
}

function Test-MemorySchema {
    param([object]$Schema)

    Test-ContainsAll $Schema.required $RequiredRecordFields "memory-schema.json.required"

    if ($Schema.additionalProperties -ne $false) {
        Add-Issue "memory-schema.json must set additionalProperties to false"
    }

    if ($Schema.properties.id.pattern -ne $MemoryIdPattern) {
        Add-Issue "memory-schema.json id pattern must be $MemoryIdPattern"
    }
    Test-ContainsAll $Schema.properties.status.enum $StatusValues "memory-schema.json.status.enum"
    Test-ContainsAll $Schema.properties.type.enum $TypeValues "memory-schema.json.type.enum"
    Test-ContainsAll $Schema.properties.source.required @("kind", "ref", "date") "memory-schema.json.source.required"
    Test-ContainsAll $Schema.properties.source.properties.kind.enum $SourceKindValues "memory-schema.json.source.kind.enum"
    Test-ContainsAll $Schema.properties.confidence.enum $ConfidenceValues "memory-schema.json.confidence.enum"

    if ($Schema.properties.source.properties.date.pattern -ne $DatePattern) {
        Add-Issue "memory-schema.json source.date pattern must be $DatePattern"
    }
    if ($Schema.properties.last_verified.pattern -ne $DatePattern) {
        Add-Issue "memory-schema.json last_verified pattern must be $DatePattern"
    }
}

function Test-RetrievalConfig {
    param([object]$Config)

    $RequiredConfigFields = @("version", "default_status_filter", "exclude_status_by_default", "source_priority", "confidence_weight", "retrieval_modes", "task_profiles", "staleness_policy", "privacy_rules")
    Test-ObjectProperties $Config $RequiredConfigFields "retrieval-config.json"
    foreach ($RequiredConfigField in $RequiredConfigFields) {
        [void](Test-RequiredProperty $Config $RequiredConfigField "retrieval-config.json")
    }

    Test-PositiveNumber $Config.version "retrieval-config.json.version"
    Test-StringEnumArray $Config.default_status_filter $StatusValues "retrieval-config.json.default_status_filter" $true
    Test-StringEnumArray $Config.exclude_status_by_default $StatusValues "retrieval-config.json.exclude_status_by_default" $true

    if ($Config.default_status_filter -notcontains "current") {
        Add-Issue "retrieval-config.json must include current in default_status_filter"
    }
    if ($Config.exclude_status_by_default -notcontains "stale") {
        Add-Issue "retrieval-config.json must exclude stale memories by default"
    }
    foreach ($Status in $StatusValues) {
        if ($Config.default_status_filter -contains $Status -and $Config.exclude_status_by_default -contains $Status) {
            Add-Issue "retrieval-config.json status '$Status' cannot be both included and excluded by default"
        }
    }

    Test-StringEnumArray $Config.source_priority $SourceKindValues "retrieval-config.json.source_priority" $true

    if ($Config.confidence_weight -isnot [pscustomobject]) {
        Add-Issue "retrieval-config.json.confidence_weight must be an object"
    }
    else {
        Test-ObjectProperties $Config.confidence_weight $ConfidenceValues "retrieval-config.json.confidence_weight"
        foreach ($Confidence in $ConfidenceValues) {
            if (Test-RequiredProperty $Config.confidence_weight $Confidence "retrieval-config.json.confidence_weight") {
                Test-PositiveNumber $Config.confidence_weight.$Confidence "retrieval-config.json.confidence_weight.$Confidence"
            }
        }
    }

    if ($Config.retrieval_modes -isnot [pscustomobject]) {
        Add-Issue "retrieval-config.json.retrieval_modes must be an object"
    }
    else {
        Test-ObjectProperties $Config.retrieval_modes @("keyword", "structured_filter", "vector") "retrieval-config.json.retrieval_modes"
        foreach ($Mode in @("keyword", "structured_filter")) {
            if (Test-RequiredProperty $Config.retrieval_modes $Mode "retrieval-config.json.retrieval_modes") {
                Test-Boolean $Config.retrieval_modes.$Mode "retrieval-config.json.retrieval_modes.$Mode"
            }
        }
        if ($null -ne $Config.retrieval_modes.vector) {
            Test-NonEmptyString $Config.retrieval_modes.vector "retrieval-config.json.retrieval_modes.vector"
        }
    }

    if ($Config.task_profiles -isnot [pscustomobject]) {
        Add-Issue "retrieval-config.json.task_profiles must be an object"
    }
    else {
        foreach ($Profile in $Config.task_profiles.PSObject.Properties) {
            Test-StringEnumArray $Profile.Value $TypeValues "retrieval-config.json.task_profiles.$($Profile.Name)" $true
        }
    }

    if ($Config.staleness_policy -isnot [pscustomobject]) {
        Add-Issue "retrieval-config.json.staleness_policy must be an object"
    }
    else {
        foreach ($Field in @("warn_after_days", "require_verification_after_days")) {
            if (Test-RequiredProperty $Config.staleness_policy $Field "retrieval-config.json.staleness_policy") {
                Test-PositiveNumber $Config.staleness_policy.$Field "retrieval-config.json.staleness_policy.$Field"
            }
        }
        if ($null -ne $Config.staleness_policy.warn_after_days -and $null -ne $Config.staleness_policy.require_verification_after_days -and $Config.staleness_policy.require_verification_after_days -lt $Config.staleness_policy.warn_after_days) {
            Add-Issue "retrieval-config.json.staleness_policy.require_verification_after_days must be greater than or equal to warn_after_days"
        }
    }

    if ($Config.privacy_rules -isnot [pscustomobject]) {
        Add-Issue "retrieval-config.json.privacy_rules must be an object"
    }
    else {
        foreach ($Field in @("forbidden_content", "require_redaction_for_real_user_data")) {
            [void](Test-RequiredProperty $Config.privacy_rules $Field "retrieval-config.json.privacy_rules")
        }
        Test-StringArray $Config.privacy_rules.forbidden_content "retrieval-config.json.privacy_rules.forbidden_content" $true
        Test-Boolean $Config.privacy_rules.require_redaction_for_real_user_data "retrieval-config.json.privacy_rules.require_redaction_for_real_user_data"
    }
}

function Test-MemoryRecord {
    param(
        [object]$Record,
        [int]$LineNumber
    )

    $RecordPath = "memories.jsonl line $LineNumber"

    Test-ObjectProperties $Record $AllowedRecordFields $RecordPath

    foreach ($RequiredField in $RequiredRecordFields) {
        [void](Test-RequiredProperty $Record $RequiredField $RecordPath)
    }

    Test-MemoryId $Record.id "$RecordPath.id"
    Test-StringEnum $Record.status $StatusValues "$RecordPath.status"
    Test-StringEnum $Record.type $TypeValues "$RecordPath.type"
    Test-StringArray $Record.scope "$RecordPath.scope" $true
    Test-NonEmptyString $Record.summary "$RecordPath.summary"
    Test-NonEmptyString $Record.content "$RecordPath.content"
    Test-StringEnum $Record.confidence $ConfidenceValues "$RecordPath.confidence"
    Test-DateString $Record.last_verified "$RecordPath.last_verified"

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
            Test-DateString $Record.source.date "$RecordPath.source.date"
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

    Test-MemoryRecordPrivacy $Record $LineNumber
}

function Test-NoForbiddenContent {
    param(
        [object]$Value,
        [string]$Path
    )

    if ($Value -isnot [string]) {
        return
    }

    foreach ($ForbiddenContent in $ForbiddenContentValues) {
        if ([string]::IsNullOrWhiteSpace($ForbiddenContent)) {
            continue
        }
        if ($Value.IndexOf($ForbiddenContent, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            Add-Issue "$Path contains forbidden content marker '$ForbiddenContent'"
        }
    }
}

function Test-StringArrayPrivacy {
    param(
        [object]$Value,
        [string]$Path
    )

    if ($Value -isnot [array]) {
        return
    }

    for ($Index = 0; $Index -lt $Value.Count; $Index += 1) {
        Test-NoForbiddenContent $Value[$Index] "$Path[$Index]"
    }
}

function Test-MemoryRecordPrivacy {
    param(
        [object]$Record,
        [int]$LineNumber
    )

    $RecordPath = "memories.jsonl line $LineNumber"
    Test-NoForbiddenContent $Record.summary "$RecordPath.summary"
    Test-NoForbiddenContent $Record.content "$RecordPath.content"
    Test-StringArrayPrivacy $Record.scope "$RecordPath.scope"

    if ($null -ne $Record.source) {
        Test-NoForbiddenContent $Record.source.ref "$RecordPath.source.ref"
    }
    if ($null -ne $Record.evidence) {
        Test-StringArrayPrivacy $Record.evidence "$RecordPath.evidence"
    }
    if ($null -ne $Record.tags) {
        Test-StringArrayPrivacy $Record.tags "$RecordPath.tags"
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
        Test-MemorySchema $Schema
    }
    catch {
        Add-Issue "memory-schema.json is not valid JSON: $($_.Exception.Message)"
    }
}

$ConfigPath = Join-Path $StoreRoot "retrieval-config.json"
if (Test-Path -LiteralPath $ConfigPath -PathType Leaf) {
    try {
        $Config = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
        Test-RetrievalConfig $Config
        if ($Config.privacy_rules.forbidden_content -is [array]) {
            $script:ForbiddenContentValues = @($Config.privacy_rules.forbidden_content)
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
