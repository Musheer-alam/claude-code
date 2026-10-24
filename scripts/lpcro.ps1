<#
LP-CRO workflow engine. Enforces the state machine in workflows/state-machine.json.

Usage (from the system root):
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts/lpcro.ps1 <command> [options]

Commands:
  init        -Url <landing-url> [-Slug s] [-Name n]       Create a project from templates; becomes active.
  use         -Slug s                                       Make an existing project active.
  list                                                      List projects.
  status      [-Json]                                       Progress board, open questions, allowed moves.
  next                                                      Agents runnable now (dependencies satisfied).
  transition  -To <STATE|RESUME> [-Reason r] [-Kind k]      Move the state machine (gated).
  agent       -Agent a -Status pending|running|done|failed|skipped
  question    -Text t [-Critical]  |  -Resolve Q-001 -Answer a
  set         -Key k -Value v
  baseline    -Cvr <pct> -Source s -Window w [-Sessions n -Conversions n -MonthlySessions n]  |  -Unavailable -Reason r
  guardrail   -Status DEFINED|UNDEFINED [-Summary s]
  risk|missing|decision  -Text t     (decision also: -Resolve <substring>)
  validate                                                  Evidence/hypothesis traceability + placeholder scan.
  merge-evidence                                            Fold evidence/shards/*.md (parallel agents) into EVIDENCE.md.
  verdict                                                   Recompute the verification verdict from verdict.json.
  render                                                    Re-render PROJECT_STATE.md.

All commands act on the active project unless -Project <slug> is given.
There is deliberately NO approve command: approval is captured only from the user's own
prompt by the UserPromptSubmit hook (scripts/hooks/capture-decision.ps1).
#>
param(
    [Parameter(Position = 0)][string]$Command = 'help',
    [string]$Project, [string]$Url, [string]$Slug, [string]$Name,
    [string]$To, [string]$Reason, [string]$Kind,
    [string]$Agent, [string]$Status, [string]$Text, [switch]$Critical,
    [string]$Resolve, [string]$Answer, [string]$Key, [string]$Value,
    [double]$Cvr = -1, [string]$Source, [string]$Window, [string]$Metric = 'CVR',
    [long]$Sessions = -1, [long]$Conversions = -1, [long]$MonthlySessions = -1,
    [switch]$Unavailable, [string]$Summary, [switch]$Json
)

. (Join-Path $PSScriptRoot 'lib\common.ps1')
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$StateOrder = @('INTAKE','DISCOVERY','RESEARCH','DIAGNOSIS','STRATEGY','ARCHITECTURE','WAITING_FOR_APPROVAL','PRODUCTION','CRITIQUE','VERIFICATION','ITERATION','COMPLETE')

function Fail([string]$msg, [int]$code = 1) {
    [Console]::Error.WriteLine("LPCRO ERROR: $msg")
    exit $code
}

function Resolve-Slug {
    if ($Project) { $s = $Project } else { $s = Get-ActiveSlug }
    if (-not $s) { Fail 'No active project. Run: lpcro.ps1 init -Url <landing-page-url>' }
    if (-not (Test-Path (Join-Path (Get-ProjectDir $s) 'state.json'))) { Fail "Project '$s' not found." }
    return $s
}

function New-Slug([string]$u) {
    $h = $u -replace '^https?://', '' -replace '^www\.', ''
    $h = ($h -replace '[^A-Za-z0-9]+', '-').Trim('-').ToLower()
    if ($h.Length -gt 48) { $h = $h.Substring(0, 48).Trim('-') }
    return $h
}

# ---------------------------------------------------------------- validation

function Get-Defs([string]$path, [string]$prefix) {
    $defs = @{}
    if (-not (Test-Path $path)) { return $defs }
    $text = Read-Utf8 $path
    if ($text.Contains($script:TemplateMarker)) { return $defs }
    $blocks = [regex]::Split($text, "(?m)^(?=###\s+$prefix-\d{3,})")
    foreach ($b in $blocks) {
        $mm = [regex]::Match($b, "^###\s+($prefix-\d{3,})")
        if ($mm.Success) { $defs[$mm.Groups[1].Value] = $b }
    }
    return $defs
}

function Get-Field([string]$block, [string]$field) {
    $mm = [regex]::Match($block, "(?im)^\s*[-*]?\s*\*\*$field\s*:?\*\*\s*:?\s*(.*)$")
    if ($mm.Success) { return $mm.Groups[1].Value.Trim() }
    return $null
}

function Get-ValidationErrors([string]$pd, [switch]$Production) {
    $errs = New-Object System.Collections.Generic.List[string]
    $ev  = Get-Defs (Join-Path $pd 'evidence\EVIDENCE.md') 'E'
    # Parallel agents write evidence/shards/<agent>.md to avoid concurrent edits of one file.
    $shardDir = Join-Path $pd 'evidence\shards'
    if (Test-Path $shardDir) {
        foreach ($sf in (Get-ChildItem $shardDir -File -Filter *.md)) {
            $sd = Get-Defs $sf.FullName 'E'
            foreach ($k in $sd.Keys) {
                if ($ev.ContainsKey($k)) { $errs.Add("evidence ID collision: $k defined twice (shard $($sf.Name))") } else { $ev[$k] = $sd[$k] }
            }
        }
    }
    $hy  = Get-Defs (Join-Path $pd 'hypotheses\HYPOTHESES.md') 'H'
    $vb  = Get-Defs (Join-Path $pd '02-customer\verbatim-bank.md') 'V'
    $cf  = Get-Defs (Join-Path $pd 'decisions\CONFLICTS.md') 'C'

    foreach ($id in $ev.Keys) {
        $src = Get-Field $ev[$id] 'Source'; $conf = Get-Field $ev[$id] 'Confidence'
        if (-not $src -or $src -match '^(TBD|TODO|\?|-|n/a)$') { $errs.Add("evidence/EVIDENCE.md: $id has no Source") }
        if (-not $conf -or $conf -notmatch '^(HIGH|MEDIUM|LOW)\b') { $errs.Add("evidence/EVIDENCE.md: $id Confidence must be HIGH|MEDIUM|LOW") }
    }
    foreach ($id in $hy.Keys) {
        $s = Get-Field $hy[$id] 'Status'
        if (-not $s -or $s -notmatch '^(UNTESTED|TESTING|VALIDATED|REJECTED)\b') { $errs.Add("hypotheses/HYPOTHESES.md: $id Status must be UNTESTED|TESTING|VALIDATED|REJECTED") }
    }
    foreach ($id in $vb.Keys) {
        $src = Get-Field $vb[$id] 'Source'
        if (-not $src -or $src -match '^(TBD|TODO|\?|-)$') { $errs.Add("02-customer/verbatim-bank.md: $id has no Source (never invent quotes)") }
    }

    $files = Get-ChildItem -Path $pd -Recurse -File -Include *.md, *.html, *.htm, *.liquid, *.tsx, *.jsx, *.vue, *.astro |
        Where-Object { $_.FullName -notmatch '\\node_modules\\' }
    foreach ($f in $files) {
        $t = Read-Utf8 $f.FullName
        if ($t.Contains($script:TemplateMarker)) { continue }
        $rel = $f.FullName.Substring($pd.Length).TrimStart('\')
        foreach ($mm in [regex]::Matches($t, '\b([EHVC])-(\d{3,})\b')) {
            $id = $mm.Value; $kind = $mm.Groups[1].Value
            $known = switch ($kind) { 'E' { $ev.ContainsKey($id) } 'H' { $hy.ContainsKey($id) } 'V' { $vb.ContainsKey($id) } 'C' { $cf.ContainsKey($id) } }
            if (-not $known) { $errs.Add("${rel}: dangling reference $id (not defined in its registry)") }
        }
    }

    $copy = Join-Path $pd '09-copy\final-copy.md'
    if (Test-Filled $copy) {
        $claimRx = '\d+(\.\d+)?\s?%|\b\d{1,3}(,\d{3})+\b|\b\d+\+|\b\d+(\.\d+)?x\b|\b\d+(\.\d+)?\s?(customers|reviews|users|clients|orders|people|stars|days|nights|years|months|weeks|hours|minutes|servings|units|sold|ratings?)\b|[' + [char]0x20B9 + [char]0x00A3 + [char]0x20AC + '$]\s?\d'
        $quoteRx = '["' + [char]0x201C + [char]0x201D + ']'
        $n = 0
        foreach ($line in ((Read-Utf8 $copy) -split "`n")) {
            $n++
            $l = $line.Trim()
            if ($l -eq '' -or $l.StartsWith('#') -or $l.StartsWith('<!--')) { continue }
            $tagged = $l -match '\[(E|V)-\d{3,}\]'
            if ($l -match $claimRx -and -not $tagged) { $errs.Add("09-copy/final-copy.md:${n}: numeric/factual claim without [E-xxx] or [V-xxx] tag -> $l") }
            if ($l.StartsWith('>') -and $l -match $quoteRx -and -not $tagged) { $errs.Add("09-copy/final-copy.md:${n}: quote/testimonial without [V-xxx] or [E-xxx] source tag -> $l") }
        }
    }

    if ($Production) {
        # Upper-case tokens are matched case-sensitively so prose like "no placeholders" is not flagged.
        $phRx = '(?i:lorem ipsum|\[insert|example\.com/your)|\bTODO\b|\bTBD\b|\bPLACEHOLDER\b|\bXX%|\bXXX\b'
        foreach ($sub in '09-copy', '10-design', '11-build') {
            $d = Join-Path $pd $sub
            if (-not (Test-Path $d)) { continue }
            foreach ($f in (Get-ChildItem $d -Recurse -File -Include *.md, *.html, *.htm, *.css, *.js, *.liquid, *.tsx, *.jsx)) {
                $t = Read-Utf8 $f.FullName
                if ($t.Contains($script:TemplateMarker)) { continue }
                $rel = $f.FullName.Substring($pd.Length).TrimStart('\')
                if ($t -cmatch $phRx) { $errs.Add("${rel}: placeholder content found ('$($Matches[0])')") }
                if ($sub -eq '11-build' -and $f.Extension -match 'html?|liquid|tsx|jsx' -and $t -match '\[(E|V|H)-\d{3,}\]') {
                    $errs.Add("${rel}: evidence tag '$($Matches[0])' leaked into production markup")
                }
            }
        }
    }
    return $errs
}

# ---------------------------------------------------------------- verdict

function Get-ComputedVerdict([string]$pd, $st) {
    $m = Get-Machine
    $r = [ordered]@{ verdict = 'INVALID'; score = $null; fails = @(); critical = @(); errors = @(); overrides = @() }
    $vp = Join-Path $pd '13-verification\verdict.json'
    if (-not (Test-Filled $vp)) { $r.errors += 'verdict.json missing or still a template'; return $r }
    $v = Read-Utf8 $vp | ConvertFrom-Json
    $crit = @($v.criteria)
    $ids = @($crit | ForEach-Object { [int]$_.id } | Sort-Object -Unique)
    if ($crit.Count -ne 25 -or $ids.Count -ne 25 -or $ids[0] -ne 1 -or $ids[24] -ne 25) { $r.errors += 'verdict.json must contain exactly criteria 1..25' ; return $r }
    $results = @{}
    foreach ($c in $crit) {
        $def = $m.verification.criteria | Where-Object { $_.id -eq [int]$c.id }
        $res = "$($c.result)".ToUpper()
        if ($res -notin 'PASS', 'FAIL', 'NA') { $r.errors += "criterion $($c.id): result must be PASS|FAIL|NA"; continue }
        if ($res -eq 'NA' -and -not $def.na_allowed) { $res = 'FAIL'; $r.overrides += "criterion $($c.id) ($($def.name)) cannot be NOT APPLICABLE -> FAIL" }
        if ($res -eq 'NA' -and -not $c.na_reason) { $r.errors += "criterion $($c.id): NA requires na_reason" }
        if ($res -eq 'FAIL' -and (-not $c.evidence -or -not $c.fix)) { $r.errors += "criterion $($c.id): FAIL requires evidence and fix" }
        $results[[int]$c.id] = $res
    }
    # Engine cross-checks: the verifier's word is not trusted where state proves otherwise.
    if ($st.ltv_guardrail.status -ne 'DEFINED' -and $results[24] -eq 'PASS') { $results[24] = 'FAIL'; $r.overrides += 'criterion 24 PASS overridden: ltv_guardrail is UNDEFINED in state' }
    if ($st.baseline.available -eq 'UNKNOWN' -and $results[21] -eq 'PASS') { $results[21] = 'FAIL'; $r.overrides += 'criterion 21 PASS overridden: baseline status never recorded' }

    $critList = @()
    foreach ($cfail in @($v.critical_failures)) {
        if (-not $cfail) { continue }
        if ($cfail.type -notin $m.verification.critical_failure_types) { $r.errors += "unknown critical failure type '$($cfail.type)'" }
        $critList += $cfail.type
    }
    if ($st.baseline.available -eq 'AVAILABLE' -and $st.baseline.value_pct -eq $null) { $critList += 'MISSING_BASELINE_WHERE_DATA_EXISTS'; $r.overrides += 'baseline data exists but no baseline value recorded' }
    if ($st.experiment.proposed -and $st.ltv_guardrail.status -ne 'DEFINED') { $critList += 'NO_LTV_GUARDRAIL_WITH_EXPERIMENT'; $r.overrides += 'experiment proposed without a defined LTV guardrail' }
    if (-not $st.project.primary_conversion) { $critList += 'MISSING_CONVERSION_OBJECTIVE'; $r.overrides += 'no primary conversion recorded in state' }
    $valErr = @(Get-ValidationErrors $pd -Production)
    if ($valErr.Count -gt 0) { $critList += 'UNSUPPORTED_FACTUAL_CLAIM'; $r.overrides += "validation found $($valErr.Count) traceability/placeholder error(s)" }

    $r.critical = @($critList | Sort-Object -Unique)
    $r.fails = @($results.Keys | Where-Object { $results[$_] -eq 'FAIL' } | Sort-Object)
    $r.score = 25 - $r.fails.Count
    if ($r.errors.Count -gt 0) { $r.verdict = 'INVALID' }
    elseif ($r.critical.Count -gt 0) { $r.verdict = 'DO_NOT_SHIP' }
    elseif ($r.score -ge $m.verification.thresholds.ship) { $r.verdict = 'SHIP' }
    elseif ($r.score -ge $m.verification.thresholds.ship_with_fixes) { $r.verdict = 'SHIP_WITH_FIXES' }
    else { $r.verdict = 'DO_NOT_SHIP' }
    if ($v.stated_verdict -and $v.stated_verdict -ne $r.verdict) { $r.overrides += "verifier stated '$($v.stated_verdict)'; engine computed '$($r.verdict)' (engine wins)" }
    return $r
}

# ---------------------------------------------------------------- checks

function Test-Fresh([string]$path, $st) {
    if ($st.iteration.count -eq 0 -or -not $st.iteration.started_at) { return $true }
    if (-not (Test-Path $path)) { return $false }
    return ((Get-Item $path).LastWriteTime -gt [datetime]::Parse($st.iteration.started_at).AddSeconds(-1))
}

function Invoke-Check([string]$check, [string]$pd, $st) {
    switch ($check) {
        'no_open_critical_questions' {
            $open = @($st.questions | Where-Object { $_.status -eq 'OPEN' -and $_.critical })
            if ($open.Count) { return "open CRITICAL question(s) must be answered by the user first: $(($open | ForEach-Object { $_.id }) -join ', ')" }
        }
        'qualification_decided' {
            if ($st.qualification -eq 'NOT_QUALIFIED') { return 'qualification is NOT_QUALIFIED: transition to BLOCKED (-Kind NOT_QUALIFIED) and consult the user' }
            if ($st.qualification -notin 'QUALIFIED', 'QUALIFIED_WITH_CAVEATS') { return "qualification not decided (is '$($st.qualification)'); run: set -Key qualification -Value QUALIFIED|QUALIFIED_WITH_CAVEATS|NOT_QUALIFIED" }
        }
        'baseline_status_recorded' {
            if ($st.baseline.available -eq 'UNKNOWN') { return 'baseline status not recorded; run: baseline -Cvr ... OR baseline -Unavailable -Reason ...' }
        }
        'evidence_valid' {
            $e = @(Get-ValidationErrors $pd)
            if ($e.Count) { return "evidence traceability errors:`n    " + ($e -join "`n    ") }
        }
        'no_placeholders' {
            $e = @(Get-ValidationErrors $pd -Production)
            if ($e.Count) { return "production validation errors:`n    " + ($e -join "`n    ") }
        }
        'no_open_conflicts' {
            $cf = Get-Defs (Join-Path $pd 'decisions\CONFLICTS.md') 'C'
            $open = @($cf.Keys | Where-Object { (Get-Field $cf[$_] 'Status') -match '^OPEN' })
            if ($open.Count) { return "unresolved conflict(s) must be decided and documented first: $($open -join ', ')" }
        }
        'approval_granted' {
            if ($st.approval.status -ne 'APPROVED') { return "user approval required (approval status is $($st.approval.status)). Present approval/BLUEPRINT.md and wait for the user to reply APPROVE." }
        }
        'blueprint_unchanged' {
            $h = Get-BlueprintHash $pd
            if ($st.approval.approved_hash -and $h -ne $st.approval.approved_hash) { return 'strategy/architecture changed after approval; move back to WAITING_FOR_APPROVAL and re-present the blueprint' }
        }
        'build_fresh_since_iteration' {
            if (-not (Test-Fresh (Join-Path $pd '11-build\build-notes.md') $st)) { return "11-build/build-notes.md not updated since iteration $($st.iteration.count) started (builder must log the fix)" }
        }
        'critic_fresh_since_iteration' {
            if (-not (Test-Fresh (Join-Path $pd '12-qa\cro-critic.md') $st)) { return "12-qa/cro-critic.md not re-run since iteration $($st.iteration.count) started" }
        }
        'verdict_fresh_since_iteration' {
            if (-not (Test-Fresh (Join-Path $pd '13-verification\verdict.json') $st)) { return "verdict.json not re-run since iteration $($st.iteration.count) started" }
        }
        'verdict_shippable' {
            $v = Get-ComputedVerdict $pd $st
            if ($v.verdict -notin 'SHIP', 'SHIP_WITH_FIXES') { return "computed verdict is $($v.verdict) (score $($v.score)/25; critical: $($v.critical -join ', '); errors: $($v.errors -join '; '))" }
        }
        'verdict_not_shippable_or_fixes_requested' {
            $v = Get-ComputedVerdict $pd $st
            if ($v.verdict -eq 'INVALID') { return "verdict.json is invalid: $($v.errors -join '; ')" }
            if ($v.verdict -eq 'SHIP') { return 'verdict is SHIP; no iteration needed (transition to COMPLETE)' }
        }
        'iterations_remaining' {
            if ($st.iteration.count -ge $st.iteration.max) { return 'MAX_ITERATIONS' }
        }
        'iteration_routed' {
            $log = Join-Path $pd 'decisions\ITERATION_LOG.md'
            if (-not (Test-Path $log) -or -not ((Read-Utf8 $log) -match "(?m)^##\s+Iteration\s+$($st.iteration.count)\b")) { return "decisions/ITERATION_LOG.md has no '## Iteration $($st.iteration.count)' routing entry (failure -> specialist mapping)" }
        }
        'final_report_filled' {
            if (-not (Test-Filled (Join-Path $pd 'FINAL_REPORT.md'))) { return 'FINAL_REPORT.md not written' }
        }
        'block_resolvable' {
            if ($st.blocked.kind -eq 'MAX_ITERATIONS' -and $st.iteration.count -ge $st.iteration.max) { return 'blocked on MAX_ITERATIONS: only the user can extend (they reply EXTEND), or the run ends here' }
            if ($st.blocked.kind -eq 'NOT_QUALIFIED' -and $st.qualification -eq 'NOT_QUALIFIED') { return 'blocked as NOT_QUALIFIED: record the user decision (set -Key qualification) before resuming' }
            if ($st.blocked.kind -eq 'USER_INPUT') {
                $open = @($st.questions | Where-Object { $_.status -eq 'OPEN' -and $_.critical })
                if ($open.Count) { return "blocked on user input; still open: $(($open | ForEach-Object { $_.id }) -join ', ')" }
            }
        }
    }
    return $null
}

function Reset-AgentsFrom([string]$fromState, $st, $m) {
    $idx = [array]::IndexOf($StateOrder, $fromState)
    for ($i = $idx; $i -lt $StateOrder.Count; $i++) {
        $sdef = $m.states.($StateOrder[$i])
        foreach ($a in @($sdef.agents)) { if ($a) { $st.agents.$a = 'pending' } }
    }
}

function Invoke-Transition([string]$slug, [string]$target, [string]$why, [string]$kind) {
    $m = Get-Machine; $st = Get-State $slug; $pd = Get-ProjectDir $slug
    $from = $st.state
    if (-not $target) { Fail 'transition requires -To <STATE>' }
    $target = $target.ToUpper()

    if ($target -eq 'BLOCKED') {
        if (-not $why) { Fail 'BLOCKED requires -Reason' }
        if (-not $kind) { $kind = 'OTHER' }
        $st.blocked.from = $from; $st.blocked.reason = $why; $st.blocked.kind = $kind.ToUpper()
        $st.history += [pscustomobject]@{ at = Get-NowIso; from = $from; to = 'BLOCKED'; reason = "[$($st.blocked.kind)] $why" }
        $st.previous_state = $from; $st.state = 'BLOCKED'; $st.final_status = 'BLOCKED'
        Save-State $slug $st
        Write-Output "BLOCKED ($($st.blocked.kind)): $why"
        return
    }
    if ($target -eq 'RESUME') {
        if ($from -ne 'BLOCKED') { Fail 'RESUME is only valid from BLOCKED' }
        $c = Invoke-Check 'block_resolvable' $pd $st
        if ($c) { Fail "cannot resume: $c" }
        $target = $st.blocked.from
        $st.history += [pscustomobject]@{ at = Get-NowIso; from = 'BLOCKED'; to = $target; reason = "resumed: $why" }
        $st.previous_state = 'BLOCKED'; $st.state = $target; $st.final_status = 'IN_PROGRESS'
        $st.blocked.from = $null; $st.blocked.reason = $null; $st.blocked.kind = $null
        Save-State $slug $st
        Write-Output "RESUMED -> $target"
        return
    }
    if (-not ($m.states.PSObject.Properties.Name -contains $target)) { Fail "unknown state '$target'" }
    if ($from -eq 'COMPLETE') { Fail 'project is COMPLETE; start a new project or a new version' }
    $allowed = @($m.states.$from.next)
    if ($target -notin $allowed) { Fail "illegal transition $from -> $target. Allowed: $($allowed -join ', ')" }

    $fi = [array]::IndexOf($StateOrder, $from); $ti = [array]::IndexOf($StateOrder, $target)
    $forward = ($ti -gt $fi) -or ($from -eq 'ITERATION')
    $errs = New-Object System.Collections.Generic.List[string]
    if ($forward) {
        foreach ($rel in @($m.states.$from.exit_requires)) {
            if ($rel -and -not (Test-Filled (Join-Path $pd $rel))) { $errs.Add("required artifact not filled: $rel (missing, near-empty, or still carries the template marker)") }
        }
        $checks = @($m.states.$from.exit_checks)
        $byT = $m.states.$from.exit_checks_by_target
        if ($byT -and ($byT.PSObject.Properties.Name -contains $target)) { $checks += @($byT.$target) }
        foreach ($c in $checks) {
            if (-not $c) { continue }
            $res = Invoke-Check $c $pd $st
            if ($res -eq 'MAX_ITERATIONS') {
                $st.blocked.from = $from; $st.blocked.kind = 'MAX_ITERATIONS'
                $st.blocked.reason = "Maximum autonomous iterations reached ($($st.iteration.max)). Unresolved issues are listed in 13-verification/final-verification.md."
                $st.history += [pscustomobject]@{ at = Get-NowIso; from = $from; to = 'BLOCKED'; reason = 'MAX_ITERATIONS' }
                $st.previous_state = $from; $st.state = 'BLOCKED'; $st.final_status = 'STOPPED_MAX_ITERATIONS'
                Save-State $slug $st
                Write-Output 'Maximum autonomous iterations reached. The following issues remain... (see 13-verification/final-verification.md). State -> BLOCKED.'
                exit 3
            }
            if ($res) { $errs.Add("[$c] $res") }
        }
    }
    foreach ($rel in @($m.states.$target.entry_requires)) {
        if ($rel -and -not (Test-Filled (Join-Path $pd $rel))) { $errs.Add("target state requires: $rel") }
    }
    if ($target -in @($m.approval_states) -and $st.approval.status -ne 'APPROVED') {
        $errs.Add("APPROVAL GATE: $target requires user approval (status: $($st.approval.status))")
    }
    if ($errs.Count) { Fail ("cannot transition $from -> ${target}:`n  - " + ($errs -join "`n  - ")) }

    # ---- effects
    if (-not $forward -and $target -ne 'PRODUCTION') {
        if ($st.approval.status -eq 'APPROVED' -and $ti -le [array]::IndexOf($StateOrder, 'WAITING_FOR_APPROVAL')) {
            $st.approval.status = 'INVALIDATED'
            $st.approval.history += [pscustomobject]@{ at = Get-NowIso; event = 'INVALIDATED'; detail = "moved back to $target" }
        }
        Reset-AgentsFrom $target $st $m
    }
    if ($from -eq 'ITERATION' -and $target -in 'STRATEGY', 'ARCHITECTURE') {
        $st.approval.status = 'INVALIDATED'
        $st.approval.history += [pscustomobject]@{ at = Get-NowIso; event = 'INVALIDATED'; detail = "iteration routed a strategic failure to $target" }
        Reset-AgentsFrom $target $st $m
    }
    if ($target -eq 'WAITING_FOR_APPROVAL') {
        $st.approval.status = 'PENDING'; $st.approval.requested_at = Get-NowIso
        $st.approval.blueprint_hash = Get-BlueprintHash $pd
        $st.approval.history += [pscustomobject]@{ at = Get-NowIso; event = 'REQUESTED'; detail = $st.approval.blueprint_hash }
    }
    if ($target -eq 'PRODUCTION' -and $from -eq 'WAITING_FOR_APPROVAL' -and [int]$st.iteration.count -eq 0) { $st.current_version = 'v1' }
    if ($target -eq 'ITERATION') {
        $st.iteration.count = [int]$st.iteration.count + 1
        $st.iteration.started_at = Get-NowIso
        $st.current_version = "v$([int]$st.iteration.count + 1)"
        $v = Get-ComputedVerdict $pd $st
        $st.iteration.log += [pscustomobject]@{ n = $st.iteration.count; at = $st.iteration.started_at; verdict = $v.verdict; score = $v.score; fails = ($v.fails -join ','); critical = ($v.critical -join ',') }
    }
    if ($from -eq 'ITERATION' -and $target -eq 'PRODUCTION') {
        foreach ($a in 'copywriter', 'designer', 'builder', 'cro-critic', 'verifier') { $st.agents.$a = 'pending' }
    }
    if ($target -eq 'VERIFICATION' -or $target -eq 'COMPLETE' -or $target -eq 'ITERATION') {
        if (Test-Filled (Join-Path $pd '13-verification\verdict.json')) {
            $v = Get-ComputedVerdict $pd $st
            $st.verification.last_verdict = $v.verdict; $st.verification.score = $v.score
            $st.verification.critical = ($v.critical -join ', '); $st.verification.at = Get-NowIso
        }
    }
    if ($target -eq 'COMPLETE') {
        if ($st.verification.last_verdict -eq 'SHIP') { $st.final_status = 'SHIP' } else { $st.final_status = 'SHIP_WITH_FIX_LIST' }
    }
    if ($forward -and $from -notin @($st.completed_states) -and $from -ne 'ITERATION') { $st.completed_states += $from }
    $st.history += [pscustomobject]@{ at = Get-NowIso; from = $from; to = $target; reason = $why }
    $st.previous_state = $from; $st.state = $target
    Save-State $slug $st
    Write-Output "OK: $from -> $target"
    if ($m.states.$target.agents) { Write-Output "Agents for ${target}: $((@($m.states.$target.agents)) -join ', ') (parallel: $($m.states.$target.parallel))" }
}

# ---------------------------------------------------------------- baseline math

function Update-Feasibility($st) {
    $m = Get-Machine
    $lift = [double]$m.experimentation.target_relative_lift
    $b = $st.baseline
    if ($b.available -ne 'AVAILABLE' -or $b.value_pct -eq $null) {
        $st.target.target_value_pct = $null
        $st.validation.status = 'NO_BASELINE'
        $st.validation.statement = '20% improvement cannot currently be validated because a reliable baseline is unavailable.'
        $st.validation.required_sessions_per_arm = $null; $st.validation.estimated_weeks = $null
    }
    else {
        $p = [double]$b.value_pct / 100.0
        $st.target.target_value_pct = [math]::Round([double]$b.value_pct * (1 + $lift), 3)
        $delta = $p * $lift
        $n = [math]::Ceiling(16 * $p * (1 - $p) / ($delta * $delta))
        $st.validation.required_sessions_per_arm = $n
        if ($b.monthly_sessions -ne $null -and [double]$b.monthly_sessions -gt 0) {
            $weekly = [double]$b.monthly_sessions / 4.345
            $weeks = [math]::Ceiling((2 * $n) / $weekly)
            $st.validation.estimated_weeks = $weeks
            if ($weeks -le [int]$m.experimentation.max_reasonable_test_weeks) {
                $st.validation.status = 'FEASIBLE'
                $st.validation.statement = "A 50/50 test needs ~$n sessions per arm (~$weeks weeks at current traffic) to detect a 20% relative lift (alpha 0.05, power 0.8, Lehr approximation)."
            } else {
                $st.validation.status = 'INSUFFICIENT_TRAFFIC'
                $st.validation.statement = "20% improvement cannot currently be statistically validated with available traffic (~$n sessions per arm needed = ~$weeks weeks). Use directional before/after reads with stated confounds."
            }
        } else {
            $st.validation.estimated_weeks = $null
            $st.validation.status = 'TRAFFIC_UNKNOWN'
            $st.validation.statement = "Needs ~$n sessions per arm to detect a 20% relative lift; monthly traffic unknown, so test duration cannot be estimated."
        }
    }
    Update-Readiness $st
}

function Update-Readiness($st) {
    $why = @()
    if ($st.baseline.available -ne 'AVAILABLE') { $why += 'no baseline' }
    if ($st.ltv_guardrail.status -ne 'DEFINED') { $why += 'LTV guardrail UNDEFINED' }
    if ($st.validation.status -notin 'FEASIBLE') { $why += "validation $($st.validation.status)" }
    if ($why.Count) { $st.experiment.readiness = "NOT_READY ($($why -join '; '))" } else { $st.experiment.readiness = 'READY' }
}

# ---------------------------------------------------------------- commands

switch ($Command.ToLower()) {

    'init' {
        if (-not $Url) { Fail 'init requires -Url (the landing-page URL is the only required input)' }
        if (-not $Slug) { $Slug = New-Slug $Url }
        $pd = Get-ProjectDir $Slug
        if (Test-Path (Join-Path $pd 'state.json')) { Fail "project '$Slug' already exists (use: use -Slug $Slug)" }
        $tpl = Join-Path (Get-SystemRoot) 'templates\project'
        New-Item -ItemType Directory -Force -Path $pd | Out-Null
        Copy-Item -Path (Join-Path $tpl '*') -Destination $pd -Recurse -Force
        $m = Get-Machine
        $agents = [ordered]@{}; foreach ($a in $m.agent_order) { $agents[$a] = 'pending' }
        if (-not $Name) { $Name = $Slug }
        $st = [pscustomobject][ordered]@{
            schema_version = '1.0'
            created_at = Get-NowIso; updated_at = Get-NowIso
            project = [pscustomobject][ordered]@{ slug = $Slug; name = $Name; landing_url = $Url; business_url = $null; product = $null; primary_conversion = $null; traffic_source = $null; codebase_path = $null }
            state = 'INTAKE'; previous_state = $null
            blocked = [pscustomobject][ordered]@{ from = $null; reason = $null; kind = $null }
            completed_states = @(); history = @()
            agents = [pscustomobject]$agents
            qualification = 'UNKNOWN'
            questions = @(); pending_decisions = @()
            approval = [pscustomobject][ordered]@{ status = 'NOT_REQUESTED'; requested_at = $null; blueprint_hash = $null; approved_at = $null; approved_hash = $null; source = $null; user_text = $null; history = @() }
            iteration = [pscustomobject][ordered]@{ count = 0; max = [int]$m.max_iterations; started_at = $null; log = @() }
            current_version = 'v0'
            baseline = [pscustomobject][ordered]@{ available = 'UNKNOWN'; metric = $null; value_pct = $null; source = $null; window = $null; sessions = $null; conversions = $null; monthly_sessions = $null; reason = $null }
            target = [pscustomobject][ordered]@{ relative_lift_pct = 20; target_value_pct = $null; statement = 'OPTIMISATION TARGET: >=20% RELATIVE improvement in the primary conversion rate where measurable. This is a target, not a guaranteed or validated result.' }
            validation = [pscustomobject][ordered]@{ status = 'NO_BASELINE'; statement = '20% improvement cannot currently be validated because a reliable baseline is unavailable.'; required_sessions_per_arm = $null; estimated_weeks = $null }
            ltv_guardrail = [pscustomobject][ordered]@{ status = 'UNDEFINED'; summary = $null }
            experiment = [pscustomobject][ordered]@{ proposed = $false; readiness = 'NOT_READY (no baseline; LTV guardrail UNDEFINED)' }
            risks = @(); missing_info = @()
            verification = [pscustomobject][ordered]@{ last_verdict = $null; score = $null; critical = $null; at = $null }
            final_status = 'IN_PROGRESS'
        }
        $st.history += [pscustomobject]@{ at = Get-NowIso; from = $null; to = 'INTAKE'; reason = 'project initialised' }
        $intake = Join-Path $pd '00-intake\intake.md'
        if (Test-Path $intake) { Write-Utf8 $intake ((Read-Utf8 $intake).Replace('{{LANDING_URL}}', $Url)) }
        Save-State $Slug $st
        Set-ActiveSlug $Slug
        Write-Output "Initialised project '$Slug' at $pd (state INTAKE, active)."
    }

    'use' {
        if (-not $Slug) { Fail 'use requires -Slug' }
        if (-not (Test-Path (Join-Path (Get-ProjectDir $Slug) 'state.json'))) { Fail "no project '$Slug'" }
        Set-ActiveSlug $Slug; Write-Output "Active project: $Slug"
    }

    'list' {
        $active = Get-ActiveSlug
        Get-ChildItem (Get-ProjectsDir) -Directory | ForEach-Object {
            $sp = Join-Path $_.FullName 'state.json'
            if (Test-Path $sp) {
                $s = Read-Utf8 $sp | ConvertFrom-Json
                $mark = ' '; if ($_.Name -eq $active) { $mark = '*' }
                Write-Output ("{0} {1,-40} {2,-22} {3}" -f $mark, $_.Name, $s.state, $s.project.landing_url)
            }
        }
    }

    'status' {
        $s = Resolve-Slug; $st = Get-State $s; $m = Get-Machine
        if ($Json) { $st | ConvertTo-Json -Depth 20; break }
        Write-Output (Get-StatusBoard $st)
        $open = @($st.questions | Where-Object { $_.status -eq 'OPEN' })
        if ($open.Count) { Write-Output "`nOpen questions:"; $open | ForEach-Object { $c = ''; if ($_.critical) { $c = ' [CRITICAL]' }; Write-Output "  $($_.id)$c $($_.text)" } }
        if ($st.state -eq 'BLOCKED') { Write-Output "`nBLOCKED [$($st.blocked.kind)] from $($st.blocked.from): $($st.blocked.reason)" }
        else { Write-Output "`nAllowed next states: $((@($m.states.($st.state).next)) -join ', ')" }
        Write-Output "Baseline: $($st.baseline.available) $($st.baseline.value_pct)  Target: $($st.target.target_value_pct)  Validation: $($st.validation.status)"
        Write-Output "LTV guardrail: $($st.ltv_guardrail.status)  Experiment: $($st.experiment.readiness)"
    }

    'next' {
        $s = Resolve-Slug; $st = Get-State $s; $m = Get-Machine
        $runnable = @()
        foreach ($a in @($m.states.($st.state).agents)) {
            if (-not $a -or $st.agents.$a -eq 'done') { continue }
            $deps = @($m.agent_dependencies.$a)
            $ok = $true
            foreach ($d in $deps) {
                if ($d -eq 'USER_APPROVAL') { if ($st.approval.status -ne 'APPROVED') { $ok = $false } }
                elseif ($st.agents.$d -notin 'done', 'skipped') { $ok = $false }
            }
            if ($ok) { $runnable += $a }
        }
        if ($runnable.Count -eq 0) {
            if (@($m.states.($st.state).agents).Count -eq 0) { Write-Output "No agents in $($st.state). Orchestrator action required." }
            else { Write-Output "All $($st.state) agents done or blocked by dependencies. Try: transition -To $((@($m.states.($st.state).next))[0])" }
        } else {
            $par = $m.states.($st.state).parallel
            Write-Output "Runnable now in $($st.state): $($runnable -join ', ')"
            if ($par -and $runnable.Count -gt 1) { Write-Output 'These are independent: spawn them in ONE message (parallel).' }
            elseif ($runnable.Count -gt 1) { Write-Output "Sequential state: run $($runnable[0]) first." }
        }
    }

    'transition' { $s = Resolve-Slug; Invoke-Transition $s $To $Reason $Kind }

    'agent' {
        $s = Resolve-Slug; $st = Get-State $s; $m = Get-Machine
        if ($Agent -notin @($m.agent_order)) { Fail "unknown agent '$Agent'. Known: $($m.agent_order -join ', ')" }
        if ($Status -notin 'pending', 'running', 'done', 'failed', 'skipped') { Fail 'status must be pending|running|done|failed|skipped' }
        if ($Status -in 'running', 'done') {
            foreach ($d in @($m.agent_dependencies.$Agent)) {
                if ($d -eq 'USER_APPROVAL') { if ($st.approval.status -ne 'APPROVED') { Fail "$Agent requires user approval first" } }
                elseif ($st.agents.$d -notin 'done', 'skipped') { Fail "$Agent depends on $d (status: $($st.agents.$d))" }
            }
        }
        $st.agents.$Agent = $Status; Save-State $s $st
        Write-Output "$Agent -> $Status"
    }

    'question' {
        $s = Resolve-Slug; $st = Get-State $s
        if ($Resolve) {
            $q = @($st.questions | Where-Object { $_.id -eq $Resolve })
            if (-not $q.Count) { Fail "no question $Resolve" }
            if (-not $Answer) { Fail 'resolve requires -Answer (use "UNKNOWN - user does not know" when applicable)' }
            $q[0].status = 'ANSWERED'; $q[0].answer = $Answer
            Save-State $s $st; Write-Output "$Resolve answered."
        } else {
            if (-not $Text) { Fail 'question requires -Text' }
            $id = 'Q-{0:D3}' -f (@($st.questions).Count + 1)
            $st.questions += [pscustomobject][ordered]@{ id = $id; text = $Text; critical = [bool]$Critical; status = 'OPEN'; answer = $null; asked_at = Get-NowIso }
            Save-State $s $st; Write-Output "$id recorded (critical: $([bool]$Critical))."
        }
    }

    'set' {
        $s = Resolve-Slug; $st = Get-State $s
        switch ($Key) {
            { $_ -in 'name', 'business_url', 'product', 'primary_conversion', 'traffic_source', 'codebase_path', 'landing_url' } { $st.project.$Key = $Value }
            'qualification' {
                if ($Value -notin 'QUALIFIED', 'QUALIFIED_WITH_CAVEATS', 'NOT_QUALIFIED', 'UNKNOWN') { Fail 'qualification: QUALIFIED|QUALIFIED_WITH_CAVEATS|NOT_QUALIFIED|UNKNOWN' }
                $st.qualification = $Value
            }
            'current_version' { $st.current_version = $Value }
            'experiment_proposed' { $st.experiment.proposed = ($Value -match '^(true|1|yes)$'); Update-Readiness $st }
            default { Fail "unsupported key '$Key'" }
        }
        Save-State $s $st; Write-Output "$Key = $Value"
    }

    'baseline' {
        $s = Resolve-Slug; $st = Get-State $s
        if ($Unavailable) {
            if (-not $Reason) { Fail 'baseline -Unavailable requires -Reason' }
            $st.baseline.available = 'UNAVAILABLE'; $st.baseline.reason = $Reason; $st.baseline.value_pct = $null
        } else {
            if ($Cvr -lt 0 -or -not $Source) { Fail 'baseline requires -Cvr <percent, e.g. 2.0> and -Source' }
            if ($Cvr -gt 100) { Fail '-Cvr is a percentage (2.0 means 2%)' }
            $st.baseline.available = 'AVAILABLE'; $st.baseline.metric = $Metric; $st.baseline.value_pct = $Cvr
            $st.baseline.source = $Source; $st.baseline.window = $Window
            if ($Sessions -ge 0) { $st.baseline.sessions = $Sessions }
            if ($Conversions -ge 0) { $st.baseline.conversions = $Conversions }
            if ($MonthlySessions -ge 0) { $st.baseline.monthly_sessions = $MonthlySessions }
        }
        Update-Feasibility $st
        Save-State $s $st
        Write-Output "Baseline: $($st.baseline.available) $($st.baseline.value_pct)%  Target: $($st.target.target_value_pct)% (20% RELATIVE)  -> $($st.validation.status): $($st.validation.statement)"
    }

    'guardrail' {
        $s = Resolve-Slug; $st = Get-State $s; $pd = Get-ProjectDir $s
        if ($Status -notin 'DEFINED', 'UNDEFINED') { Fail 'guardrail -Status DEFINED|UNDEFINED' }
        if ($Status -eq 'DEFINED') {
            $plan = Join-Path $pd '07-strategy\experiment-plan.md'
            if (-not (Test-Filled $plan)) { Fail 'DEFINED requires 07-strategy/experiment-plan.md to be written first' }
            $t = Read-Utf8 $plan
            if ($t -notmatch '(?m)PROMOTE' -or $t -notmatch '(?m)KILL') { Fail 'experiment-plan.md must contain explicit PROMOTE and KILL rules with thresholds' }
            if ($t.Contains('___')) { Fail 'experiment-plan.md still has blank thresholds (___); get the numbers from the user first' }
            if (-not $Summary) { Fail 'DEFINED requires -Summary with the numeric thresholds' }
        }
        $st.ltv_guardrail.status = $Status; $st.ltv_guardrail.summary = $Summary
        Update-Readiness $st; Save-State $s $st
        Write-Output "LTV guardrail: $Status. Experiment readiness: $($st.experiment.readiness)"
    }

    'risk'    { $s = Resolve-Slug; $st = Get-State $s; if (-not $Text) { Fail '-Text required' }; $st.risks += $Text; Save-State $s $st; Write-Output 'risk recorded' }
    'missing' { $s = Resolve-Slug; $st = Get-State $s; if (-not $Text) { Fail '-Text required' }; $st.missing_info += $Text; Save-State $s $st; Write-Output 'missing info recorded' }
    'decision' {
        $s = Resolve-Slug; $st = Get-State $s
        if ($Resolve) { $st.pending_decisions = @($st.pending_decisions | Where-Object { $_ -notlike "*$Resolve*" }) }
        elseif ($Text) { $st.pending_decisions += $Text }
        else { Fail '-Text or -Resolve required' }
        Save-State $s $st; Write-Output 'pending decisions updated'
    }

    'validate' {
        $s = Resolve-Slug; $st = Get-State $s; $pd = Get-ProjectDir $s
        $prod = ([array]::IndexOf($StateOrder, $st.state) -ge [array]::IndexOf($StateOrder, 'PRODUCTION'))
        if ($prod) { $e = @(Get-ValidationErrors $pd -Production) } else { $e = @(Get-ValidationErrors $pd) }
        if ($e.Count) { Write-Output "VALIDATION FAILED ($($e.Count)):"; $e | ForEach-Object { Write-Output "  - $_" }; exit 1 }
        Write-Output 'VALIDATION PASSED: all E-/H-/V-/C- references resolve; sources present; no placeholders.'
    }

    'verdict' {
        $s = Resolve-Slug; $st = Get-State $s; $pd = Get-ProjectDir $s
        $v = Get-ComputedVerdict $pd $st
        Write-Output "VERDICT: $($v.verdict)   score $($v.score)/25"
        Write-Output "FAILED criteria: $(@($v.fails) -join ', ')"
        Write-Output "Critical failures: $(@($v.critical) -join ', ')"
        foreach ($o in $v.overrides) { Write-Output "  engine override: $o" }
        foreach ($e in $v.errors) { Write-Output "  schema error: $e" }
    }

    'merge-evidence' {
        # Run by the orchestrator after a parallel state: fold evidence/shards/*.md into EVIDENCE.md (ID order).
        $s = Resolve-Slug; $pd = Get-ProjectDir $s
        $main = Join-Path $pd 'evidence\EVIDENCE.md'; $shardDir = Join-Path $pd 'evidence\shards'
        if (-not (Test-Path $shardDir)) { Write-Output 'No shards to merge.'; break }
        $existing = Get-Defs $main 'E'
        $blocks = @{}
        foreach ($sf in (Get-ChildItem $shardDir -File -Filter *.md)) {
            $sd = Get-Defs $sf.FullName 'E'
            foreach ($k in $sd.Keys) {
                if ($existing.ContainsKey($k) -or $blocks.ContainsKey($k)) { Fail "ID collision on $k (shard $($sf.Name)); renumber before merging" }
                $blocks[$k] = $sd[$k].TrimEnd()
            }
        }
        $text = (Read-Utf8 $main).TrimEnd()
        foreach ($k in ($blocks.Keys | Sort-Object)) { $text += "`n`n" + $blocks[$k] }
        Write-Utf8 $main ($text + "`n")
        Get-ChildItem $shardDir -File -Filter *.md | Remove-Item -Force
        Write-Output "Merged $($blocks.Count) evidence entries into evidence/EVIDENCE.md."
    }

    'render' { $s = Resolve-Slug; $st = Get-State $s; Save-State $s $st; Write-Output 'PROJECT_STATE.md rendered' }

    default {
        Get-Content $MyInvocation.MyCommand.Path -TotalCount 30 | Select-Object -Skip 1 | ForEach-Object { Write-Output $_ }
    }
}
