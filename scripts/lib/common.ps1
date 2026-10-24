# LP-CRO shared library. Dot-sourced by scripts/lpcro.ps1 and scripts/hooks/*.ps1.
# Keep this file ASCII-only: Windows PowerShell 5.1 reads BOM-less scripts as ANSI.

$ErrorActionPreference = 'Stop'

$script:TemplateMarker = '<!-- LPCRO:TEMPLATE -->'

function Get-SystemRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}

function Get-ProjectsDir {
    if ($env:LPCRO_PROJECTS) { $d = $env:LPCRO_PROJECTS } else { $d = Join-Path (Get-SystemRoot) 'projects' }
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
    return (Resolve-Path $d).Path
}

function Get-Machine {
    $p = Join-Path (Get-SystemRoot) 'workflows\state-machine.json'
    return (Get-Content -Raw -Encoding UTF8 $p | ConvertFrom-Json)
}

function Get-NowIso { return (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK') }

function Write-Utf8 {
    param([string]$Path, [string]$Text)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding $false))
}

function Read-Utf8 {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Get-ActiveSlug {
    $f = Join-Path (Get-ProjectsDir) '.active'
    if (Test-Path $f) { return (Read-Utf8 $f).Trim() }
    return $null
}

function Set-ActiveSlug {
    param([string]$Slug)
    Write-Utf8 (Join-Path (Get-ProjectsDir) '.active') $Slug
}

function Get-ProjectDir {
    param([string]$Slug)
    return (Join-Path (Get-ProjectsDir) $Slug)
}

function Get-State {
    param([string]$Slug)
    $p = Join-Path (Get-ProjectDir $Slug) 'state.json'
    if (-not (Test-Path $p)) { throw "No state.json for project '$Slug' ($p)" }
    return (Read-Utf8 $p | ConvertFrom-Json)
}

function Save-State {
    param([string]$Slug, $State)
    $State.updated_at = Get-NowIso
    $p = Join-Path (Get-ProjectDir $Slug) 'state.json'
    Write-Utf8 $p ($State | ConvertTo-Json -Depth 20)
    Write-ProjectStateMd $Slug $State
}

function Test-Filled {
    # A required artifact is "filled" when it exists, is non-trivial, and no longer carries the template marker.
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $false }
    if ($Path -like '*.json') {
        try { $j = Read-Utf8 $Path | ConvertFrom-Json } catch { return $false }
        if ($j.PSObject.Properties.Name -contains '_template' -and $j._template) { return $false }
        return $true
    }
    $t = Read-Utf8 $Path
    if ($t.Length -lt 40) { return $false }
    if ($t.Contains($script:TemplateMarker)) { return $false }
    return $true
}

function Get-BlueprintHash {
    param([string]$ProjectDir)
    $m = Get-Machine
    $sb = New-Object System.Text.StringBuilder
    foreach ($rel in $m.blueprint_files) {
        $p = Join-Path $ProjectDir $rel
        [void]$sb.Append("==$rel==`n")
        if (Test-Path $p) { [void]$sb.Append(((Read-Utf8 $p) -replace "`r`n", "`n")) }
    }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($sb.ToString())
    $sha = [System.Security.Cryptography.SHA256]::Create()
    return ([System.BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').ToLower()
}

function Get-Glyph {
    param([string]$Status)
    switch ($Status) {
        'done'    { return [string][char]0x2713 }   # check mark
        'running' { return [string][char]0x27F3 }   # clockwise arrow
        'failed'  { return [string][char]0x2717 }   # ballot x
        'skipped' { return '-' }
        default   { return [string][char]0x25CB }   # white circle
    }
}

function Get-StatusBoard {
    param($State)
    $m = Get-Machine
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('LANDING PAGE CRO SYSTEM')
    $lines.Add("Project:        $($State.project.name) ($($State.project.slug))")
    $lines.Add("URL:            $($State.project.landing_url)")
    $lines.Add("Current phase:  $($State.state)")
    $lines.Add("Version:        $($State.current_version)   Iteration: $($State.iteration.count)/$($State.iteration.max)")
    $lines.Add("Approval:       $($State.approval.status)")
    $lines.Add('Agents:')
    foreach ($a in $m.agent_order) {
        $s = $State.agents.$a
        $lines.Add("  $(Get-Glyph $s) $a")
        if ($a -eq 'page-architect') {
            if ($State.approval.status -eq 'APPROVED') { $g = Get-Glyph 'done' }
            elseif ($State.state -eq 'WAITING_FOR_APPROVAL') { $g = Get-Glyph 'running' }
            else { $g = Get-Glyph 'pending' }
            $lines.Add("  $g USER APPROVAL GATE")
        }
    }
    return ($lines -join "`n")
}

function Format-List {
    param($Items, [string]$Empty = 'None recorded')
    $arr = @($Items)
    if ($arr.Count -eq 0) { return "- $Empty" }
    return (($arr | ForEach-Object { "- $_" }) -join "`n")
}

function Write-ProjectStateMd {
    param([string]$Slug, $State)
    $q = @($State.questions | Where-Object { $_.status -eq 'OPEN' } | ForEach-Object {
        $crit = ''; if ($_.critical) { $crit = ' **[CRITICAL]**' }
        "$($_.id)$crit $($_.text)"
    })
    $hist = @($State.history | Select-Object -Last 12 | ForEach-Object { "| $($_.at) | $($_.from) | $($_.to) | $($_.reason) |" })
    $b = $State.baseline
    if ($b.value_pct -ne $null) { $baseTxt = "$($b.metric) = $($b.value_pct)% (source: $($b.source); window: $($b.window))" }
    else { $baseTxt = "NOT AVAILABLE ($($b.available))" }
    if ($State.target.target_value_pct -ne $null) { $tgtTxt = "$($State.target.target_value_pct)% ($($State.target.relative_lift_pct)% RELATIVE lift over baseline; optimisation TARGET, not a validated result)" }
    else { $tgtTxt = ">= $($State.target.relative_lift_pct)% relative improvement (cannot be computed: no baseline)" }

    $md = @"
# PROJECT_STATE

> Rendered automatically by ``scripts/lpcro.ps1`` from ``state.json``. Do not edit by hand; use the engine.

``````
$(Get-StatusBoard $State)
``````

| Field | Value |
|---|---|
| Project | $($State.project.name) |
| Slug | $($State.project.slug) |
| Landing URL | $($State.project.landing_url) |
| Business URL | $($State.project.business_url) |
| Product / service | $($State.project.product) |
| Primary conversion | $($State.project.primary_conversion) |
| Codebase path | $($State.project.codebase_path) |
| Current phase | **$($State.state)** |
| Completed phases | $((@($State.completed_states)) -join ', ') |
| Active agents | $((@($State.agents.PSObject.Properties | Where-Object { $_.Value -eq 'running' } | ForEach-Object { $_.Name })) -join ', ') |
| Qualification | $($State.qualification) |
| User approval | $($State.approval.status) $(if ($State.approval.approved_at) { "(at $($State.approval.approved_at), source: $($State.approval.source))" }) |
| Current version | $($State.current_version) |
| Iteration count | $($State.iteration.count) / $($State.iteration.max) |
| Baseline | $baseTxt |
| Target | $tgtTxt |
| Validation feasibility | $($State.validation.status): $($State.validation.statement) |
| LTV guardrail | $($State.ltv_guardrail.status) $(if ($State.ltv_guardrail.summary) { "- $($State.ltv_guardrail.summary)" }) |
| Experiment readiness | $($State.experiment.readiness) |
| Last verification | $($State.verification.last_verdict) (score $($State.verification.score)/25, critical $($State.verification.critical)) |
| Final status | **$($State.final_status)** |

## Open questions for the user
$(Format-List $q 'None')

## Pending decisions
$(Format-List $State.pending_decisions 'None')

## Known risks
$(Format-List $State.risks)

## Missing information
$(Format-List $State.missing_info)

## Blocked
$(if ($State.state -eq 'BLOCKED') { "- From: $($State.blocked.from)`n- Kind: $($State.blocked.kind)`n- Reason: $($State.blocked.reason)" } else { '- Not blocked' })

## Recent transitions
| At | From | To | Reason |
|---|---|---|---|
$($hist -join "`n")
"@
    Write-Utf8 (Join-Path (Get-ProjectDir $Slug) 'PROJECT_STATE.md') $md
}

function Read-HookInput {
    # Hooks receive a JSON payload on stdin.
    $raw = [Console]::In.ReadToEnd()
    if (-not $raw) { return $null }
    try { return ($raw | ConvertFrom-Json) } catch { return $null }
}
