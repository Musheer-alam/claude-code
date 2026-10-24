# Workflow: Landing Page Optimization (state machine)

Enforced by `scripts/lpcro.ps1` against `workflows/state-machine.json`. The orchestrator (main session) drives it; specialists execute inside states. All paths are relative to `projects/<slug>/`.

```
INTAKE ─► DISCOVERY ─► RESEARCH ─► DIAGNOSIS ─► STRATEGY ─► ARCHITECTURE ─► WAITING_FOR_APPROVAL
            │  ▲          (02‖03‖04)   (05‖06)       (07)          (08)              │   ▲
            │  └─ CHECKPOINT 1: critical questions                          CHECKPOINT 2: user APPROVE
            ▼                                                                         │   │ REVISE → back to owning state
         BLOCKED ◄────────────── any state (with reason & kind) ─────────────────────┘   │
                                                                                         ▼
 COMPLETE ◄── VERIFICATION ◄── CRITIQUE ◄── PRODUCTION (09 → 10 → 11)  ◄───────────────────
     ▲             │  (13)        (12)          ▲
     │             └─► ITERATION (count ≤ 3) ───┘  (or → STRATEGY/ARCHITECTURE: approval invalidated, re-approve)
     └── SHIP / SHIP_WITH_FIXES          count = 3 and still failing → BLOCKED (MAX_ITERATIONS) → user EXTEND or stop
```

## 1. States

| State | Agents (parallel?) | Enters when | Exit gate (engine-enforced) |
|---|---|---|---|
| INTAKE | — (orchestrator) | `init -Url` | `00-intake/intake.md` filled |
| DISCOVERY | discovery | intake recorded | `01-discovery/discovery.md`; no OPEN critical questions; qualification ∈ {QUALIFIED, QUALIFIED_WITH_CAVEATS} |
| RESEARCH | customer-intelligence ‖ platform-analysis ‖ competitive-intelligence (**parallel**) | discovery done | 02 (both files), 03, 04 filled; baseline status recorded (`baseline …` or `baseline -Unavailable`); evidence valid |
| DIAGNOSIS | cro-auditor ‖ positioning (**parallel**) | research done | 05 (both), 06 filled; evidence valid |
| STRATEGY | conversion-strategist | diagnosis done | 07 strategy + hypotheses + experiment plan; evidence valid; **no OPEN conflicts** |
| ARCHITECTURE | page-architect | strategy done | 08 archetype, page-map, section-jobs, wireframe-spec; evidence valid |
| WAITING_FOR_APPROVAL | — (orchestrator presents `approval/BLUEPRINT.md`) | architecture done; blueprint filled; blueprint hash stored | → PRODUCTION only if approval = APPROVED (set solely by the user's typed reply via hook) **and** blueprint hash unchanged since approval |
| PRODUCTION | copywriter → designer → builder (**sequential**) | approved | 09, 10 (3 files), 11 build-notes filled; evidence valid; no placeholders; no evidence tags in markup; build-notes fresh if iterating |
| CRITIQUE | cro-critic (independent) | build done | `12-qa/cro-critic.md` (fresh if iterating) |
| VERIFICATION | verifier (independent) | critique done | `final-verification.md` + `verdict.json` (fresh if iterating). → COMPLETE needs engine-computed SHIP / SHIP_WITH_FIXES + FINAL_REPORT. → ITERATION needs DO_NOT_SHIP / SHIP_WITH_FIXES and iterations remaining |
| ITERATION | — (orchestrator routes) | verification failed | `decisions/ITERATION_LOG.md` has `## Iteration N` routing table → PRODUCTION (tactical) or STRATEGY / ARCHITECTURE (strategic; approval invalidated) |
| COMPLETE | — | shippable verdict + final report | terminal |
| BLOCKED | — | any state, with `-Reason` and `-Kind` (USER_INPUT, NOT_QUALIFIED, URL_INACCESSIBLE, MAX_ITERATIONS, CONFLICT, OTHER) | `transition -To RESUME` once resolvable (MAX_ITERATIONS needs the user's EXTEND) |

Moving backwards (e.g. REVISE → STRATEGY) resets agent statuses from that state onward and invalidates a previous approval.

## 2. Dependencies (engine: `lpcro.ps1 next`)

```
discovery ─┬─► customer-intelligence ─┐
           ├─► platform-analysis ─────┼─► cro-auditor ─┐
           └─► competitive-intelligence┘   positioning ─┴─► conversion-strategist ─► page-architect ─► [USER APPROVAL] ─► copywriter ─► designer ─► builder ─► cro-critic ─► verifier
```
Parallel groups are genuinely independent: 02/03/04 each read only discovery + intake and write disjoint folders; 05 and 06 both read 01–04 and write disjoint folders. To keep writes disjoint, **agents running in a parallel state register evidence in their own shard** `evidence/shards/<agent>.md` (not in `EVIDENCE.md`), using their ID block (customer E-100–199, platform E-200–299, market E-300–399, auditor E-400–499, positioning E-500–599; discovery E-001–099; later agents E-600+). The validator reads shards as part of the registry and flags ID collisions. After the parallel state completes, the orchestrator runs `lpcro.ps1 merge-evidence` to fold shards into `EVIDENCE.md`. Sequential agents append to `EVIDENCE.md` directly.

## 3. Orchestrator loop (every turn)

1. `lpcro.ps1 status` (resume from files, not memory).
2. If BLOCKED → explain the block and what the user can do. If WAITING_FOR_APPROVAL → see §5.
3. `lpcro.ps1 next` → runnable agents. Mark each `agent -Status running`, spawn them (all parallel ones **in one message**), each with a brief: project path, which files to read, which to write, ID block, open questions relevant to it.
4. On each handoff report: `agent -Status done|failed`; record questions (`question`), risks, missing info, conflicts (`decisions/CONFLICTS.md`).
5. Detect conflicts between handoffs (§9). Resolve by evidence hierarchy or escalate.
6. When the state's agents are done → `transition -To <next>`. If refused, route the gap to the owning agent (do not hand-fill specialist artifacts).
7. Show the progress board (§11).

## 4. Checkpoint 1 — missing critical information (DISCOVERY)

The discovery agent proposes questions, each tagged CRITICAL / NICE-TO-HAVE with the decision it unlocks. The orchestrator:
- asks the user **only** CRITICAL ones (batched, one message, numbered), records them with `question -Critical`, and ends the turn;
- records NICE-TO-HAVE ones as `missing` and proceeds;
- if the user does not know, resolves with `-Answer "UNKNOWN – user does not know"`; downstream agents treat it as UNKNOWN (never as a guess).
If the user supplied enough up front, there are no critical questions and the run continues automatically.

## 5. Checkpoint 2 — strategy & architecture approval

1. From ARCHITECTURE, orchestrator compiles `approval/BLUEPRINT.md` (template: summary, archetype + why, section/job/reason table, top hypotheses, target statement, evidence gaps, open conflicts) from 01–08 — summarising, not inventing.
2. `transition -To WAITING_FOR_APPROVAL` (engine stores the blueprint hash).
3. Show the blueprint to the user in chat (concise, same structure) and ask **APPROVE STRATEGY AND ARCHITECTURE?** with options 1 APPROVE · 2 REVISE · 3 ASK QUESTIONS · 4 START OVER. **End the turn.** Do not use a multiple-choice tool for this — approval is captured only from the user's typed message by the `capture-decision` hook.
4. Next turn, the hook's note tells you the outcome:
   - APPROVED → `transition -To PRODUCTION`.
   - REVISION_REQUESTED → identify the owning agent(s) (positioning? strategy? architecture?), `transition` back to that state only, re-run just those agents with the user's change as the brief, rebuild the blueprint, re-request approval. Do not restart the workflow.
   - QUESTIONS → answer from artifacts; approval stays PENDING.
   - RESTART_REQUESTED → confirm scope with the user; transition back to INTAKE/DISCOVERY/RESEARCH accordingly.
   - Ambiguous text containing "approve" is **not** approval.
5. If anything in the blueprint files changes after it was shown, the hash check voids approval.

## 6. Production, critique, verification, iteration

- PRODUCTION is sequential: copywriter (09) → *internal copy gate*: `lpcro.ps1 validate` must pass (every numeric claim and quote tagged and resolvable) → designer (10) → builder (11). The user is not asked to approve copy separately (two human checkpoints only), but the orchestrator may show the hero copy in the progress update.
- CRITIQUE: cro-critic tries to break the page (original vs new). Its failures go to the verifier as input, not as fixes.
- VERIFICATION: verifier scores 25 criteria into `verdict.json`; `lpcro.ps1 verdict` recomputes (engine overrides: NA on non-NA criteria → FAIL; criterion 24 can't PASS while guardrail UNDEFINED; criterion 21 can't PASS with baseline status unknown; any validation error → critical UNSUPPORTED_FACTUAL_CLAIM; missing baseline where data exists → critical).
  - 24–25 & no critical → SHIP → write FINAL_REPORT → COMPLETE.
  - 21–23 & no critical → SHIP_WITH_FIXES → either COMPLETE with the named fix list in FINAL_REPORT, or ITERATION if fixes are cheap and internal.
  - < 21 or any critical → DO_NOT_SHIP → ITERATION.
- ITERATION (do not ask the user first): write `## Iteration N` in `decisions/ITERATION_LOG.md` mapping each failure → root cause → specialist → fix instruction; decide if internally fixable. Copy/claims → copywriter; layout/hierarchy/visual → designer; code/a11y/perf/CTA → builder; single message / audience / offer / archetype → strategist or architect (**strategic**: requires re-approval). Then PRODUCTION → CRITIQUE → VERIFICATION again.
- **Hard limit:** 3 iterations. The engine refuses a 4th, moves to BLOCKED (MAX_ITERATIONS) and the orchestrator says: *"Maximum autonomous iterations reached. The following issues remain..."* followed by the unresolved list. Only the user's reply EXTEND [n] raises the cap.
- Not internally fixable (needs proof the business doesn't have, legal sign-off, assets, data) → BLOCKED (USER_INPUT) with the exact ask.

## 7. Experimentation & the 20% target

- Target: **≥20% relative** improvement of the primary CVR where measurable. `target = baseline × 1.2` (2.0% → 2.4%). Percentage points are never used for the target.
- `lpcro.ps1 baseline` computes the sample size per arm (Lehr: n = 16·p(1−p)/(0.2p)², α 0.05, power 0.8) and weeks at current traffic; > 8 weeks = INSUFFICIENT_TRAFFIC.
- Required wording:
  - no baseline → "20% improvement cannot currently be validated because a reliable baseline is unavailable."
  - insufficient traffic → "20% improvement cannot currently be statistically validated with available traffic."
- Track CVR, AOV, revenue per visitor, return rate, repeat rate, LTV. CVR alone never decides.
- Statuses: TARGET (everywhere pre-launch) vs VALIDATED RESULT (only after the pre-registered decision read). Hypotheses move UNTESTED → TESTING → VALIDATED / REJECTED only on such reads.

## 8. LTV / wrong-win guardrail

Before any experiment is called ready: PROMOTE and KILL rules with numeric thresholds in `07-strategy/experiment-plan.md`, agreed with the user, then `guardrail -Status DEFINED -Summary "…"`. Without the data: `LTV GUARDRAIL: UNDEFINED`, ask the user for AOV/return-rate/LTV/margin inputs, and the experiment stays NOT_READY. Proposing an experiment (`set -Key experiment_proposed -Value true`) with an undefined guardrail is a critical verification failure.

## 9. Conflict resolution

Disagreement between agents or sources is never silently resolved. Orchestrator writes `C-xxx` in `decisions/CONFLICTS.md` (Status OPEN), then asks: *which evidence has stronger support?* using the hierarchy 1 behavioural data · 2 customer interviews · 3 first-party analytics · 4 primary sources · 5 repeated observed patterns · 6 inference · 7 generic assumptions. Resolve and log a DECISION, or escalate to the user (Status ESCALATED_TO_USER) when evidence is evenly matched and the choice changes strategy. The engine refuses to leave STRATEGY with any OPEN conflict.

## 10. Failure handling

| Situation | Behaviour |
|---|---|
| URL inaccessible / blocked / bot-wall | Try WebFetch → built-in browser → Claude in Chrome (if user allows); then ask user for HTML/screenshots. If none: BLOCKED (URL_INACCESSIBLE). Never audit a page you didn't see. |
| JS-rendered page | Use the browser tools; record method in intake. |
| Analytics unavailable | Platform agent writes `NOT AVAILABLE`, lists what each source would answer, `baseline -Unavailable`; strategy proceeds on public evidence, confidence lowered. |
| No customer interviews | `INTERVIEW DATA: NOT AVAILABLE`; mine public VOC; mark n≥5 unmet; confidence lowered; never synthesise interviews. |
| No ad data | Message-match criterion uses observable ads (e.g. ad libraries) or is NA with reason; recorded as missing. |
| No baseline | Exact §7 wording; criterion 21 PASS only if the gap and a pre-launch capture plan are explicit. |
| No source code | Builder ships a standalone, self-contained page in `11-build/` with integration notes. |
| No brand assets | Designer derives tokens from the live page and says so. |
| Insufficient traffic | §7 wording; recommend directional reads and qualitative validation; no significance claims. |
| Conflicting evidence / agent conclusions | §9. |
| Unsupported claims | Validator blocks transitions; copy may only state what the evidence registry supports. |
| Missing conversion data | Primary conversion must still be named (from page/discovery); if not determinable → CRITICAL question. |
| Not qualified | BLOCKED (NOT_QUALIFIED) with reasons; user decides whether to proceed with caveats. |

## 11. Output experience

After each phase, show only the board (from `lpcro.ps1 status`) plus 1–3 lines: what finished, key finding, what is next. Example:

```
LANDING PAGE CRO SYSTEM
Project:        acme-sleep-mask
Current phase:  RESEARCH
Agents:
  ✓ discovery
  ✓ customer-intelligence
  ⟳ platform-analysis
  ⟳ competitive-intelligence
  ○ cro-auditor
  ...
```
No internal reasoning dumps. Deliverables are linked by path.

## 12. Stop conditions

COMPLETE (shippable verdict + FINAL_REPORT) · BLOCKED on user input / not qualified / inaccessible URL · MAX_ITERATIONS reached · user STOP. Every stop writes or updates FINAL_REPORT.md (partial if blocked) with what is done, what remains, and why.
