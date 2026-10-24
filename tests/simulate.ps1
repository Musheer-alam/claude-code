<#
End-to-end simulation of the LP-CRO state machine on a HYPOTHETICAL landing-page project.
Exercises every state, every gate, both hooks, the iteration loop and its hard cap, and engine overrides.
No agents are spawned: artifacts are written as fixtures so the test is deterministic.

Run:  powershell -NoProfile -ExecutionPolicy Bypass -File tests/simulate.ps1
Writes tests/SIMULATION_REPORT.md and tests/simulation-output/.
#>
$ErrorActionPreference = 'Continue'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$engine = Join-Path $root 'scripts\lpcro.ps1'
$guard = Join-Path $root 'scripts\hooks\guard.ps1'
$capture = Join-Path $root 'scripts\hooks\capture-decision.ps1'
$env:LPCRO_PROJECTS = Join-Path $env:TEMP ("lpcro-sim-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $env:LPCRO_PROJECTS | Out-Null
$results = New-Object System.Collections.Generic.List[object]
$log = New-Object System.Collections.Generic.List[string]

function Text { process { if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.Exception.Message } else { "$_" } } }
function E {
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $engine @args 2>&1 | Text | Out-String
    $code = $LASTEXITCODE
    $log.Add("> lpcro $($args -join ' ')  [exit $code]`n$($out.Trim())")
    return [pscustomobject]@{ code = $code; out = $out }
}
function Hook([string]$script, $payload) {
    $json = $payload | ConvertTo-Json -Depth 6 -Compress
    $out = $json | & powershell -NoProfile -ExecutionPolicy Bypass -File $script 2>&1 | Text | Out-String
    $code = $LASTEXITCODE
    $log.Add("> hook $(Split-Path -Leaf $script) $json  [exit $code]`n$($out.Trim())")
    return [pscustomobject]@{ code = $code; out = $out }
}
function Check([string]$name, [bool]$cond, [string]$detail = '') {
    $results.Add([pscustomobject]@{ name = $name; pass = $cond; detail = $detail })
    $mark = 'FAIL'; if ($cond) { $mark = 'PASS' }
    Write-Host ("[{0}] {1}" -f $mark, $name)
}
function P([string]$rel) { return (Join-Path $script:pd $rel) }
function Fill([string]$rel, [string]$text) {
    $p = P $rel; $d = Split-Path -Parent $p
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
    [System.IO.File]::WriteAllText($p, $text, (New-Object System.Text.UTF8Encoding $false))
}
function State { return (Get-Content -Raw (P 'state.json') | ConvertFrom-Json) }
function Agents([string[]]$names, [string]$status) { foreach ($n in $names) { E agent -Agent $n -Status $status | Out-Null } }

# ===================================================================== SCENARIO A
Write-Host "`n=== SCENARIO A: hypothetical 'Lumen weighted sleep mask' PDP, full lifecycle ===" -ForegroundColor Cyan
$r = E init -Url 'https://lumen-sleep.test/products/weighted-mask' -Slug 'lumen-sleep-mask' -Name 'Lumen Sleep Mask (hypothetical)'
$script:pd = Join-Path $env:LPCRO_PROJECTS 'lumen-sleep-mask'
Check 'A01 init from URL only -> INTAKE' ($r.code -eq 0 -and (State).state -eq 'INTAKE')
Check 'A02 templates copied (registries, 13 folders)' ((Test-Path (P 'evidence\EVIDENCE.md')) -and (Test-Path (P '13-verification\verdict.json')) -and (Test-Path (P 'PROJECT_STATE.md')))

$r = E transition -To RESEARCH
Check 'A03 illegal jump INTAKE->RESEARCH refused' ($r.code -ne 0 -and $r.out -match 'illegal transition')
$r = E transition -To DISCOVERY
Check 'A04 INTAKE exit refused while intake.md is still a template' ($r.code -ne 0 -and $r.out -match '00-intake/intake.md')

Fill '00-intake\intake.md' "# 00 Intake`n| Landing page URL | https://lumen-sleep.test/products/weighted-mask | user |`nAll other fields: NOT PROVIDED. Connected tools: none confirmed. Reachable: YES (fixture)."
$r = E transition -To DISCOVERY
Check 'A05 INTAKE -> DISCOVERY' ($r.code -eq 0 -and (State).state -eq 'DISCOVERY')
E agent -Agent discovery -Status running | Out-Null

Fill '01-discovery\discovery.md' "# 01 Discovery`nBusiness: hypothetical D2C sleep accessories brand [E-001]. Primary conversion: UNKNOWN (page has Buy and Quiz CTAs). Qualification: pending user answer."
Fill 'evidence\EVIDENCE.md' @"
# Evidence Registry

### E-001
- **Claim:** Business sells a weighted sleep mask D2C (hypothetical fixture)
- **Source:** https://lumen-sleep.test/products/weighted-mask (fixture, 2026-10-22)
- **Grade:** OBSERVED
- **Agent:** discovery
- **Confidence:** HIGH
- **Used by:** Discovery
"@
$r = E question -Text 'Is the primary conversion the purchase or the sleep-quiz signup?' -Critical
Check 'A06 critical question recorded (Checkpoint 1)' ($r.code -eq 0 -and @((State).questions).Count -eq 1)
$r = E transition -To RESEARCH
Check 'A07 DISCOVERY exit refused: open critical question + qualification undecided' ($r.code -ne 0 -and $r.out -match 'CRITICAL question' -and $r.out -match 'qualification not decided')
E question -Resolve 'Q-001' -Answer 'Purchase (user, chat)' | Out-Null
E set -Key primary_conversion -Value 'Purchase (add to cart -> checkout)' | Out-Null
E set -Key qualification -Value 'QUALIFIED' | Out-Null
E agent -Agent discovery -Status done | Out-Null
$r = E transition -To RESEARCH
Check 'A08 DISCOVERY -> RESEARCH after answer + qualification' ($r.code -eq 0 -and (State).state -eq 'RESEARCH')

$r = E next
Check 'A09 orchestrator dependency resolver: 3 research agents runnable in parallel' ($r.out -match 'customer-intelligence' -and $r.out -match 'platform-analysis' -and $r.out -match 'competitive-intelligence' -and $r.out -match 'ONE message')
$r = E agent -Agent cro-auditor -Status running
Check 'A10 dependency enforcement: cro-auditor cannot start before research' ($r.code -ne 0 -and $r.out -match 'depends on')
Agents @('customer-intelligence', 'platform-analysis', 'competitive-intelligence') 'running'

Fill '02-customer\customer-intelligence.md' "# 02 Customer`nINTERVIEW DATA: NOT AVAILABLE. Top theme: light leaks wake people at dawn [V-001]. Rating context [E-101]. Unregistered claim [E-150]."
Fill '02-customer\verbatim-bank.md' @"
# Verbatim Bank

### V-001
- **Quote:** "the sun hits my face at 5am and I'm done for the day"
- **Source:** fixture review #12, https://reviews.test/lumen/12
- **Source type:** REVIEW
- **Context:** hypothetical reviewer, shift worker
- **Theme:** problem
- **Confidence:** MEDIUM
- **Usable in public copy:** YES
"@
Fill 'evidence\shards\customer-intelligence.md' @"
### E-101
- **Claim:** Product page displays 4.8 average from 2,140 reviews (brand claim)
- **Source:** https://lumen-sleep.test/products/weighted-mask (fixture, 2026-10-22)
- **Grade:** OBSERVED
- **Agent:** customer-intelligence
- **Confidence:** MEDIUM
- **Used by:** Copy
"@
Fill 'evidence\shards\platform-analysis.md' @"
### E-201
- **Claim:** Baseline purchase CVR 2.0% on 40,000 monthly sessions (fixture)
- **Source:** GA4 fixture export, 2026-09-01..2026-09-28
- **Grade:** VERIFIED
- **Agent:** platform-analysis
- **Confidence:** HIGH
- **Used by:** Strategy, Experiment
"@
Fill '03-data\platform-analysis.md' "# 03 Data`nBaseline CVR 2.0% [E-201]. Mobile 78% of sessions. Biggest leak: hero to pack selector."
Fill '04-market\competitive-intelligence.md' "# 04 Market`nCompetitors all claim 'total blackout'; nobody addresses pressure/weight comfort. Observed claims only."
$r = E transition -To DIAGNOSIS
Check 'A11 RESEARCH exit refused: dangling evidence ref + baseline status unknown' ($r.code -ne 0 -and $r.out -match 'E-150' -and $r.out -match 'baseline status not recorded')
Fill '02-customer\customer-intelligence.md' "# 02 Customer`nINTERVIEW DATA: NOT AVAILABLE. Top theme: light leaks wake people at dawn [V-001]. Rating context [E-101]."
$r = E baseline -Cvr 2.0 -Source 'GA4 fixture purchase/sessions' -Window '2026-09-01..2026-09-28' -Sessions 37000 -Conversions 740 -MonthlySessions 40000
$s = State
Check 'A12 20% target is RELATIVE: 2.0% -> 2.4% (not 22%)' ([double]$s.target.target_value_pct -eq 2.4)
Check 'A13 sample-size feasibility computed (19,600/arm, FEASIBLE)' ($s.validation.required_sessions_per_arm -eq 19600 -and $s.validation.status -eq 'FEASIBLE')
Fill 'evidence\shards\competitive-intelligence.md' "### E-101`n- **Claim:** duplicate id from a parallel agent`n- **Source:** fixture`n- **Confidence:** LOW"
$r = E validate
Check 'A13b parallel evidence shards: ID collision between agents is caught' ($r.code -ne 0 -and $r.out -match 'collision')
Remove-Item (P 'evidence\shards\competitive-intelligence.md')
$r = E merge-evidence
$evText = Get-Content -Raw (P 'evidence\EVIDENCE.md')
Check 'A13c merge-evidence folds shards into EVIDENCE.md after the parallel state' ($r.code -eq 0 -and $evText -match '### E-101' -and $evText -match '### E-201' -and @(Get-ChildItem (P 'evidence\shards') -File).Count -eq 0)
Agents @('customer-intelligence', 'platform-analysis', 'competitive-intelligence') 'done'
$r = E transition -To DIAGNOSIS
Check 'A14 RESEARCH -> DIAGNOSIS' ($r.code -eq 0 -and (State).state -eq 'DIAGNOSIS')

Agents @('cro-auditor', 'positioning') 'running'
Fill '05-audit\existing-page-audit.md' "# 05 Audit`nF-01 Hero is category-first; customers describe dawn light [V-001]. P1."
Fill '05-audit\conversion-leak-inventory.md' "# Leaks`n| 1 | L-01 | Category-first hero | P1 | [V-001] |"
Fill '06-positioning\positioning.md' "# 06 Positioning`nRecruit light-sensitive sleepers, not discount hunters. Discount forbidden above the fold. LTV guardrail: UNDEFINED until return-rate data arrives."
Agents @('cro-auditor', 'positioning') 'done'
$r = E transition -To STRATEGY
Check 'A15 DIAGNOSIS (parallel 05||06) -> STRATEGY' ($r.code -eq 0)

E agent -Agent conversion-strategist -Status running | Out-Null
Fill '07-strategy\conversion-strategy.md' "# 07 Strategy`nOne job: purchase. Core message: sleep past sunrise without pressure on your eyes [V-001]. Hypothesis H-001."
Fill '07-strategy\conversion-hypotheses.md' "# Hypotheses`n| 1 | H-001 | Customer-language hero | CVR | returns | MEDIUM |"
Fill '07-strategy\experiment-plan.md' "# Experiment plan`nBaseline 2.0% [E-201]; target 2.4% relative.`nPROMOTE if CVR up AND AOV not down more than 5% AND return rate not up more than 1.5 pp.`nKILL if CVR up BUT return rate up more than 1.5 pp OR 60-day repeat down more than 10%."
Fill 'hypotheses\HYPOTHESES.md' @"
# Hypothesis Registry

### H-001
- **Problem:** Category-first hero
- **Evidence:** [V-001]
- **Change:** Customer-language problem/outcome hero
- **Expected mechanism:** faster relevance recognition
- **Primary metric:** purchase CVR
- **Guardrail:** return rate, AOV
- **Confidence:** MEDIUM
- **Status:** UNTESTED
"@
Fill 'decisions\CONFLICTS.md' @"
# Conflict Register

### C-001
- **Status:** OPEN
- **Position A:** customer-intelligence: price is the top objection [V-001]
- **Position B:** platform-analysis: high-LTV buyers are price-insensitive [E-201]
"@
E agent -Agent conversion-strategist -Status done | Out-Null
$r = E transition -To ARCHITECTURE
Check 'A16 STRATEGY exit refused while conflict C-001 is OPEN' ($r.code -ne 0 -and $r.out -match 'C-001')
Fill 'decisions\CONFLICTS.md' @"
# Conflict Register

### C-001
- **Status:** RESOLVED
- **Position A:** customer-intelligence: price is the top objection [V-001]
- **Position B:** platform-analysis: high-LTV buyers are price-insensitive [E-201]
- **Resolution:** behavioural data (tier 1) outranks review language; price handled in FAQ, not hero.
"@
$r = E transition -To ARCHITECTURE
Check 'A17 STRATEGY -> ARCHITECTURE after conflict resolved on evidence hierarchy' ($r.code -eq 0)

E agent -Agent page-architect -Status running | Out-Null
Fill '08-architecture\page-archetype.md' "# Archetype`nProblem-solution PDP hybrid: cold paid social, problem-aware [V-001]."
Fill '08-architecture\page-map.md' "# Page map`n| 1 | Hero | recognise dawn-light problem | relevance | 5 | primary |`n| 2 | Pack choice | commercial choice | price | 4 | primary |"
Fill '08-architecture\section-jobs.md' "# Section jobs`n## 01 Hero - Job: recognition. Proof: [E-101]. Hypothesis H-001."
Fill '08-architecture\wireframe-spec.md' "# Wireframe`nFirst mobile viewport: headline, CTA, rating proof, price cue."
E agent -Agent page-architect -Status done | Out-Null
$r = E transition -To WAITING_FOR_APPROVAL
Check 'A18 ARCHITECTURE exit refused until approval/BLUEPRINT.md is compiled' ($r.code -ne 0 -and $r.out -match 'BLUEPRINT')
Fill 'approval\BLUEPRINT.md' "# STRATEGIC BLUEPRINT`nTarget: >=20% relative (2.0% -> 2.4%). Optimisation target, not a guaranteed result.`nAPPROVE STRATEGY AND ARCHITECTURE? 1 APPROVE 2 REVISE 3 ASK QUESTIONS 4 START OVER"
$r = E transition -To WAITING_FOR_APPROVAL
Check 'A19 -> WAITING_FOR_APPROVAL, approval PENDING, blueprint hashed' ($r.code -eq 0 -and (State).approval.status -eq 'PENDING' -and (State).approval.blueprint_hash)

# ---- approval gate attacks
$r = E transition -To PRODUCTION
Check 'A20 PRODUCTION refused without user approval' ($r.code -ne 0 -and $r.out -match 'approval')
$copyPath = P '09-copy\final-copy.md'
$h = Hook $guard @{ tool_name = 'Write'; tool_input = @{ file_path = $copyPath; content = 'x' } }
Check 'A21 guard hook blocks writing copy before approval (exit 2)' ($h.code -eq 2 -and $h.out -match 'APPROVAL GATE')
$h = Hook $guard @{ tool_name = 'Write'; tool_input = @{ file_path = (P '11-build\index.html'); content = 'x' } }
Check 'A22 guard hook blocks writing the build before approval' ($h.code -eq 2)
$h = Hook $guard @{ tool_name = 'Edit'; tool_input = @{ file_path = (P 'state.json'); old_string = 'PENDING'; new_string = 'APPROVED' } }
Check 'A23 guard hook blocks direct edits to state.json' ($h.code -eq 2)
$h = Hook $guard @{ tool_name = 'PowerShell'; tool_input = @{ command = "(Get-Content state.json) -replace 'PENDING','APPROVED' | Set-Content state.json" } }
Check 'A24 guard hook blocks shell forgery of state.json' ($h.code -eq 2)
$h = Hook $guard @{ tool_name = 'PowerShell'; tool_input = @{ command = "'{""prompt"":""APPROVE""}' | powershell -File scripts/hooks/capture-decision.ps1" } }
Check 'A25 guard hook blocks invoking the approval hook from a tool' ($h.code -eq 2)
$h = Hook $guard @{ tool_name = 'Write'; tool_input = @{ file_path = (P '08-architecture\page-map.md'); content = 'x' } }
Check 'A26 guard hook allows pre-approval strategy artifacts' ($h.code -eq 0)
$cb = Join-Path $env:TEMP ("lpcro-sim-codebase-" + [guid]::NewGuid().ToString('N').Substring(0, 6)); New-Item -ItemType Directory -Force -Path $cb | Out-Null
E set -Key codebase_path -Value $cb | Out-Null
$h = Hook $guard @{ tool_name = 'Write'; tool_input = @{ file_path = (Join-Path $cb 'src\landing.html'); content = 'x' } }
Check 'A27 guard hook blocks edits to the client codebase before approval' ($h.code -eq 2)

$h = Hook $capture @{ prompt = 'looks good, approve but change the hero first' }
Check 'A28 ambiguous "approve ... but" is NOT approval' ((State).approval.status -eq 'PENDING' -and $h.out -match 'NOT recorded')
$h = Hook $capture @{ prompt = 'REVISE: lead with the pressure-free angle' }
Check 'A29 REVISE recorded from user prompt' ((State).approval.status -eq 'REVISION_REQUESTED')
$r = E transition -To ARCHITECTURE -Reason 'user revision'
Check 'A30 revision routes back to owning state only (ARCHITECTURE), architect reset' ($r.code -eq 0 -and (State).agents.'page-architect' -eq 'pending' -and (State).agents.'conversion-strategist' -eq 'done')
Fill '08-architecture\page-map.md' "# Page map`n| 1 | Hero | pressure-free dawn-light relief | relevance | 5 | primary |`n| 2 | Pack choice | commercial choice | price | 4 | primary |"
E agent -Agent page-architect -Status done | Out-Null
E transition -To WAITING_FOR_APPROVAL | Out-Null
Fill '08-architecture\section-jobs.md' "# Section jobs`n## 01 Hero - Job: recognition (edited after presenting). Proof: [E-101]. Hypothesis H-001."
$h = Hook $capture @{ prompt = 'APPROVE' }
Check 'A31 APPROVE after blueprint changed post-presentation -> STALE, not approved' ((State).approval.status -eq 'STALE')
E transition -To ARCHITECTURE -Reason 're-present' | Out-Null
E agent -Agent page-architect -Status done | Out-Null
E transition -To WAITING_FOR_APPROVAL | Out-Null
$h = Hook $capture @{ prompt = 'APPROVE' }
$s = State
Check 'A32 user APPROVE recorded by hook only, bound to blueprint hash' ($s.approval.status -eq 'APPROVED' -and $s.approval.source -eq 'user-prompt-hook' -and $s.approval.approved_hash -eq $s.approval.blueprint_hash)
$h = Hook $guard @{ tool_name = 'Write'; tool_input = @{ file_path = $copyPath; content = 'x' } }
Check 'A33 guard allows copy after approval' ($h.code -eq 0)
$orig = Get-Content -Raw (P '08-architecture\section-jobs.md')
Fill '08-architecture\section-jobs.md' ($orig + "`nSneaky post-approval change.")
$r = E transition -To PRODUCTION
Check 'A34 post-approval blueprint tampering blocks PRODUCTION' ($r.code -ne 0 -and $r.out -match 'changed after approval')
Fill '08-architecture\section-jobs.md' $orig
$r = E transition -To PRODUCTION
Check 'A35 WAITING_FOR_APPROVAL -> PRODUCTION (v1)' ($r.code -eq 0 -and (State).current_version -eq 'v1')

# ---- production
Agents @('copywriter') 'running'
Fill '09-copy\final-copy.md' "# Final copy`n### 01 Hero`n**Headline:** Sleep past sunrise.`n**Proof:** Rated 4.8 by 2,140 sleepers`n> ""the sun hits my face at 5am and I'm done for the day""`n**CTA:** Get my mask"
Fill '10-design\design-system.md' "# Design system`nTokens derived from existing page: ink #1a1a1a, accent reserved for primary CTA."
Fill '10-design\design-spec.md' "# Design spec`nFirst viewport: headline dominant, rating proof under it, CTA full-width."
Fill '10-design\component-spec.md' "# Components`nProofRow, PackCard, FaqItem share 16px padding."
Fill '11-build\build-notes.md' "# Build notes`nNo codebase: standalone 11-build/index.html. CTA -> /cart/add."
Fill '11-build\index.html' "<!doctype html><title>Lumen</title><h1>Sleep past sunrise.</h1><p>Rated 4.8 by 2,140 sleepers [E-101]</p><p>TODO testimonial</p><a href='/cart/add'>Get my mask</a>"
$r = E transition -To CRITIQUE
Check 'A36 PRODUCTION exit refused: untagged numeric claim, untagged quote, placeholder, tag leaked into markup' ($r.code -ne 0 -and $r.out -match 'without \[E-xxx\]' -and $r.out -match 'quote/testimonial' -and $r.out -match 'placeholder' -and $r.out -match 'leaked')
Fill '09-copy\final-copy.md' "# Final copy`n### 01 Hero`n**Headline:** Sleep past sunrise.`n**Proof:** Rated 4.8 by 2,140 sleepers [E-101]`n> ""the sun hits my face at 5am and I'm done for the day"" [V-001]`n**CTA:** Get my mask"
Fill '11-build\index.html' "<!doctype html><title>Lumen</title><h1>Sleep past sunrise.</h1><p>Rated 4.8 by 2,140 sleepers</p><blockquote>the sun hits my face at 5am and I'm done for the day</blockquote><a href='/cart/add'>Get my mask</a>"
Agents @('copywriter', 'designer', 'builder') 'done'
$r = E transition -To CRITIQUE
Check 'A37 PRODUCTION -> CRITIQUE once copy validates (internal copy gate)' ($r.code -eq 0)
Fill '12-qa\cro-critic.md' "# Critique v1`nX-01 COPY P1: no expectation-setting on adjustment period. Route: copywriter."
$r = E transition -To VERIFICATION
Check 'A38 CRITIQUE -> VERIFICATION' ($r.code -eq 0)

function Write-Verdict([string[]]$fails, [string[]]$nas = @(), [object[]]$crit = @(), [string]$stated = 'DO_NOT_SHIP') {
    $crs = @()
    for ($i = 1; $i -le 25; $i++) {
        $res = 'PASS'; $fix = ''; $na = ''
        if ("$i" -in $fails) { $res = 'FAIL'; $fix = "fix for criterion $i" }
        elseif ("$i" -in $nas) { $res = 'NA'; $na = 'not applicable in fixture' }
        $crs += [ordered]@{ id = $i; result = $res; evidence = "fixture evidence $i"; fix = $fix; na_reason = $na }
    }
    $obj = [ordered]@{ version = (State).current_version; iteration = (State).iteration.count; stated_verdict = $stated; criteria = $crs; critical_failures = @($crit) }
    Fill '13-verification\verdict.json' ($obj | ConvertTo-Json -Depth 6)
    Fill '13-verification\final-verification.md' "# Final verification $((State).current_version)`n25 criteria scored against the rendered page. Failed criteria: $(if ($fails.Count) { $fails -join ', ' } else { 'none' })."
}

Write-Verdict -fails @('8', '10', '17', '23', '25')
$r = E verdict
Check 'A39 engine recomputes verdict: 5 stated FAILs + criterion 24 overridden (guardrail UNDEFINED) = 19/25 -> DO_NOT_SHIP' ($r.out -match 'VERDICT: DO_NOT_SHIP' -and $r.out -match 'score 19/25' -and $r.out -match 'criterion 24 PASS overridden')
$r = E transition -To COMPLETE
Check 'A40 COMPLETE refused on DO_NOT_SHIP' ($r.code -ne 0)

# ---- iteration loop: 1 (tactical), 2 (strategic -> re-approval), 3, then cap
Start-Sleep -Seconds 2
$r = E transition -To ITERATION
$s = State
Check 'A41 VERIFICATION -> ITERATION 1 (no user prompt), version v2' ($r.code -eq 0 -and $s.iteration.count -eq 1 -and $s.current_version -eq 'v2')
$r = E transition -To PRODUCTION
Check 'A42 ITERATION exit refused without a routing entry in ITERATION_LOG' ($r.code -ne 0 -and $r.out -match 'Iteration 1')
Fill 'decisions\ITERATION_LOG.md' "# Iteration Log`n## Iteration 1 (v2)`n| 10 Expectation setting | missing adjustment period | copywriter | add 3-night adjustment note | yes |"
$r = E transition -To PRODUCTION
Check 'A43 ITERATION 1 -> PRODUCTION; production agents reset to pending' ($r.code -eq 0 -and (State).agents.copywriter -eq 'pending' -and (State).agents.verifier -eq 'pending')
$r = E transition -To CRITIQUE
Check 'A44 CRITIQUE refused: builder did not log the fix (build-notes stale)' ($r.code -ne 0 -and $r.out -match 'not updated since iteration')
Fill '11-build\build-notes.md' "# Build notes`nNo codebase: standalone. Iteration log: v2 adds adjustment note."
Agents @('copywriter', 'designer', 'builder') 'done'
E transition -To CRITIQUE | Out-Null
$r = E transition -To VERIFICATION
Check 'A45 VERIFICATION refused: critic did not re-run this iteration' ($r.code -ne 0 -and $r.out -match 'cro-critic.md not re-run')
Fill '12-qa\cro-critic.md' "# Critique v2`nX-01 DESIGN P1: rating proof not visible in the first mobile viewport. Route: designer."
E transition -To VERIFICATION | Out-Null
$r = E transition -To ITERATION
Check 'A46 ITERATION refused: verifier did not re-run this iteration' ($r.code -ne 0 -and $r.out -match 'verdict.json not re-run')
Write-Verdict -fails @('4', '17', '18', '23', '25')
Start-Sleep -Seconds 2
$r = E transition -To ITERATION
Check 'A47 VERIFICATION -> ITERATION 2' ($r.code -eq 0 -and (State).iteration.count -eq 2)
Fill 'decisions\ITERATION_LOG.md' "# Iteration Log`n## Iteration 1 (v2)`ncopy fix`n## Iteration 2 (v3)`n| 4 Differentiation | archetype hides pressure-free mechanism | page-architect | STRATEGIC: move mechanism up | - |"
$r = E transition -To ARCHITECTURE -Reason 'strategic failure'
Check 'A48 strategic failure routed to ARCHITECTURE invalidates approval' ($r.code -eq 0 -and (State).approval.status -eq 'INVALIDATED')
$h = Hook $guard @{ tool_name = 'Write'; tool_input = @{ file_path = $copyPath; content = 'x' } }
Check 'A49 guard re-locks production while approval is invalidated' ($h.code -eq 2)
Fill '08-architecture\page-map.md' "# Page map`n| 1 | Hero | pressure-free dawn-light relief | relevance | 5 | primary |`n| 2 | Mechanism | why no eye pressure | doubt | 5 | none |`n| 3 | Pack choice | commercial choice | price | 4 | primary |"
E agent -Agent page-architect -Status done | Out-Null
E transition -To WAITING_FOR_APPROVAL | Out-Null
Hook $capture @{ prompt = '/lp-approve' } | Out-Null
$r = E transition -To PRODUCTION
Check 'A50 re-approval via /lp-approve -> PRODUCTION keeps version v3' ($r.code -eq 0 -and (State).current_version -eq 'v3')
Fill '11-build\build-notes.md' "# Build notes`nIteration 2: mechanism section added."
Agents @('copywriter', 'designer', 'builder') 'done'
E transition -To CRITIQUE | Out-Null
Fill '12-qa\cro-critic.md' "# Critique v3`nX-01 DESIGN P1: hero image still outranks the headline on mobile. Route: designer."
E transition -To VERIFICATION | Out-Null
Write-Verdict -fails @('17', '18', '19', '23', '25')
Start-Sleep -Seconds 2
$r = E transition -To ITERATION
Check 'A51 VERIFICATION -> ITERATION 3' ($r.code -eq 0 -and (State).iteration.count -eq 3)
Fill 'decisions\ITERATION_LOG.md' "# Iteration Log`n## Iteration 1`ncopy`n## Iteration 2`nstrategic`n## Iteration 3`n| 18 Hierarchy | CTA outranked by image | designer | reweight | - |"
E transition -To PRODUCTION | Out-Null
Fill '11-build\build-notes.md' "# Build notes`nIteration 3: hero image reduced, headline and CTA reweighted per designer."
Agents @('copywriter', 'designer', 'builder') 'done'
E transition -To CRITIQUE | Out-Null
Fill '12-qa\cro-critic.md' "# Critique v4`nX-01 DESIGN P1: proof row still below the first mobile viewport. Route: designer."
E transition -To VERIFICATION | Out-Null
Write-Verdict -fails @('17', '18', '19', '23', '25')
$r = E transition -To ITERATION
$s = State
Check 'A52 4th iteration refused: hard cap -> BLOCKED (MAX_ITERATIONS), exit 3' ($r.code -eq 3 -and $s.state -eq 'BLOCKED' -and $s.blocked.kind -eq 'MAX_ITERATIONS' -and $s.iteration.count -eq 3)
Check 'A53 stop message: "Maximum autonomous iterations reached. The following issues remain..."' ($r.out -match 'Maximum autonomous iterations reached\. The following issues remain')
$r = E transition -To RESUME
Check 'A54 RESUME refused until the user extends' ($r.code -ne 0 -and $r.out -match 'EXTEND')
Hook $capture @{ prompt = 'EXTEND 1' } | Out-Null
$r = E transition -To RESUME
Check 'A55 user EXTEND raises cap; RESUME -> VERIFICATION' ($r.code -eq 0 -and (State).state -eq 'VERIFICATION' -and (State).iteration.max -eq 4)

# ---- engine overrides on the verdict
Write-Verdict -fails @() -nas @('1')
$r = E verdict
Check 'A56 NA on a non-NA criterion (1) is converted to FAIL' ($r.out -match 'criterion 1 .* cannot be NOT APPLICABLE')
Write-Verdict -fails @()
$r = E verdict
Check 'A57 criterion 24 PASS overridden while LTV guardrail UNDEFINED' ($r.out -match 'criterion 24 PASS overridden' -and $r.out -match 'score 24/25')
E set -Key experiment_proposed -Value true | Out-Null
$r = E verdict
Check 'A58 experiment proposed without guardrail = critical -> DO_NOT_SHIP' ($r.out -match 'NO_LTV_GUARDRAIL_WITH_EXPERIMENT' -and $r.out -match 'VERDICT: DO_NOT_SHIP')
$r = E guardrail -Status DEFINED -Summary 'PROMOTE: CVR up, AOV -5% max, returns +1.5pp max; KILL: returns >+1.5pp or 60d repeat -10%'
Check 'A59 guardrail DEFINED only with numeric PROMOTE/KILL plan' ($r.code -eq 0 -and (State).ltv_guardrail.status -eq 'DEFINED')
$r = E verdict
Check 'A60 all criteria pass + guardrail defined -> SHIP 25/25' ($r.out -match 'VERDICT: SHIP\s' -and $r.out -match 'score 25/25')
$r = E transition -To COMPLETE
Check 'A61 COMPLETE refused without FINAL_REPORT.md' ($r.code -ne 0 -and $r.out -match 'FINAL_REPORT')
Fill 'FINAL_REPORT.md' "# FINAL REPORT (hypothetical)`nBaseline 2.0% [E-201]; target 2.4% (20% relative) - TARGET, not a validated result. Guardrail defined. QA 25/25."
$r = E transition -To COMPLETE
Check 'A62 VERIFICATION -> COMPLETE (final_status SHIP)' ($r.code -eq 0 -and (State).state -eq 'COMPLETE' -and (State).final_status -eq 'SHIP')
$r = E transition -To PRODUCTION
Check 'A63 COMPLETE is terminal' ($r.code -ne 0)
$visited = @((State).history | ForEach-Object { $_.to } | Sort-Object -Unique)
$all = 'INTAKE','DISCOVERY','RESEARCH','DIAGNOSIS','STRATEGY','ARCHITECTURE','WAITING_FOR_APPROVAL','PRODUCTION','CRITIQUE','VERIFICATION','ITERATION','COMPLETE','BLOCKED'
$missing = @($all | Where-Object { $_ -notin $visited })
Check 'A64 all 13 states visited in scenario A' ($missing.Count -eq 0) ("missing: $($missing -join ',')")
$outDir = Join-Path $PSScriptRoot 'simulation-output'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Copy-Item (P 'PROJECT_STATE.md') (Join-Path $outDir 'scenario-A-PROJECT_STATE.md') -Force
Copy-Item (P 'state.json') (Join-Path $outDir 'scenario-A-state.json') -Force

# ===================================================================== SCENARIO B
Write-Host "`n=== SCENARIO B: missing data, not qualified, low traffic ===" -ForegroundColor Cyan
E init -Url 'https://tiny-shop.test/lp' -Slug 'tiny-shop' | Out-Null
$script:pd = Join-Path $env:LPCRO_PROJECTS 'tiny-shop'
Fill '00-intake\intake.md' "# Intake`nLanding URL only. Everything else NOT PROVIDED."
E transition -To DISCOVERY | Out-Null
Fill '01-discovery\discovery.md' "# Discovery`nNo commercial conversion path found on the page. Qualification: NOT_QUALIFIED."
E set -Key qualification -Value NOT_QUALIFIED | Out-Null
$r = E transition -To RESEARCH
Check 'B01 NOT_QUALIFIED blocks research and tells orchestrator to consult user' ($r.code -ne 0 -and $r.out -match 'NOT_QUALIFIED')
E transition -To BLOCKED -Kind NOT_QUALIFIED -Reason 'no conversion path' | Out-Null
$r = E transition -To RESUME
Check 'B02 cannot resume a NOT_QUALIFIED block without a user decision' ($r.code -ne 0)
E set -Key qualification -Value QUALIFIED_WITH_CAVEATS | Out-Null
$r = E transition -To RESUME
Check 'B03 user decision (proceed with caveats) -> resume to DISCOVERY' ($r.code -eq 0 -and (State).state -eq 'DISCOVERY')
E baseline -Unavailable -Reason 'no analytics connected, no exports' | Out-Null
$s = State
Check 'B04 no baseline -> exact required sentence' ($s.validation.statement -eq '20% improvement cannot currently be validated because a reliable baseline is unavailable.')
Check 'B05 no baseline -> no target value invented' ($null -eq $s.target.target_value_pct)
E baseline -Cvr 1.0 -Source 'user-provided estimate' -Window 'last month' -MonthlySessions 3000 | Out-Null
$s = State
Check 'B06 low traffic -> INSUFFICIENT_TRAFFIC with exact sentence' ($s.validation.status -eq 'INSUFFICIENT_TRAFFIC' -and $s.validation.statement -like '20% improvement cannot currently be statistically validated with available traffic*')
$r = E guardrail -Status DEFINED -Summary 'guess'
Check 'B07 guardrail cannot be DEFINED without a written PROMOTE/KILL plan' ($r.code -ne 0)
Check 'B08 experiment readiness NOT_READY without guardrail' ((State).experiment.readiness -like 'NOT_READY*')
Copy-Item (P 'PROJECT_STATE.md') (Join-Path $outDir 'scenario-B-PROJECT_STATE.md') -Force

# ===================================================================== report
$pass = @($results | Where-Object { $_.pass }).Count
$total = $results.Count
$lines = @("# Simulation Report", "", "Generated $(Get-Date -Format 'yyyy-MM-dd HH:mm') by ``tests/simulate.ps1`` against a temporary projects dir. Hypothetical projects only; no agents spawned (fixture artifacts).", "", "**Result: $pass / $total assertions passed.**", "", "| # | Assertion | Result | Detail |", "|---|---|---|---|")
foreach ($x in $results) { $m = 'FAIL'; if ($x.pass) { $m = 'PASS' }; $id, $rest = $x.name -split ' ', 2; $lines += "| $id | $rest | $m | $($x.detail) |" }
$lines += @("", "## Scenario A final board", "", '```', (Get-Content -Raw (Join-Path $outDir 'scenario-A-PROJECT_STATE.md') | Select-String -Pattern '(?s)```\r?\n(.*?)```' | ForEach-Object { $_.Matches[0].Groups[1].Value }).Trim(), '```')
[System.IO.File]::WriteAllText((Join-Path $PSScriptRoot 'SIMULATION_REPORT.md'), ($lines -join "`n"), (New-Object System.Text.UTF8Encoding $false))
[System.IO.File]::WriteAllText((Join-Path $outDir 'engine-transcript.log'), ($log -join "`n`n"), (New-Object System.Text.UTF8Encoding $false))
Remove-Item -Recurse -Force $env:LPCRO_PROJECTS, $cb -ErrorAction SilentlyContinue
Write-Host "`n$pass / $total assertions passed. Report: tests/SIMULATION_REPORT.md"
if ($pass -ne $total) { exit 1 }
exit 0
