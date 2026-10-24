# Simulation Report

Generated 2026-10-22 22:56 by `tests/simulate.ps1` against a temporary projects dir. Hypothetical projects only; no agents spawned (fixture artifacts).

**Result: 74 / 74 assertions passed.**

| # | Assertion | Result | Detail |
|---|---|---|---|
| A01 | init from URL only -> INTAKE | PASS |  |
| A02 | templates copied (registries, 13 folders) | PASS |  |
| A03 | illegal jump INTAKE->RESEARCH refused | PASS |  |
| A04 | INTAKE exit refused while intake.md is still a template | PASS |  |
| A05 | INTAKE -> DISCOVERY | PASS |  |
| A06 | critical question recorded (Checkpoint 1) | PASS |  |
| A07 | DISCOVERY exit refused: open critical question + qualification undecided | PASS |  |
| A08 | DISCOVERY -> RESEARCH after answer + qualification | PASS |  |
| A09 | orchestrator dependency resolver: 3 research agents runnable in parallel | PASS |  |
| A10 | dependency enforcement: cro-auditor cannot start before research | PASS |  |
| A11 | RESEARCH exit refused: dangling evidence ref + baseline status unknown | PASS |  |
| A12 | 20% target is RELATIVE: 2.0% -> 2.4% (not 22%) | PASS |  |
| A13 | sample-size feasibility computed (19,600/arm, FEASIBLE) | PASS |  |
| A13b | parallel evidence shards: ID collision between agents is caught | PASS |  |
| A13c | merge-evidence folds shards into EVIDENCE.md after the parallel state | PASS |  |
| A14 | RESEARCH -> DIAGNOSIS | PASS |  |
| A15 | DIAGNOSIS (parallel 05||06) -> STRATEGY | PASS |  |
| A16 | STRATEGY exit refused while conflict C-001 is OPEN | PASS |  |
| A17 | STRATEGY -> ARCHITECTURE after conflict resolved on evidence hierarchy | PASS |  |
| A18 | ARCHITECTURE exit refused until approval/BLUEPRINT.md is compiled | PASS |  |
| A19 | -> WAITING_FOR_APPROVAL, approval PENDING, blueprint hashed | PASS |  |
| A20 | PRODUCTION refused without user approval | PASS |  |
| A21 | guard hook blocks writing copy before approval (exit 2) | PASS |  |
| A22 | guard hook blocks writing the build before approval | PASS |  |
| A23 | guard hook blocks direct edits to state.json | PASS |  |
| A24 | guard hook blocks shell forgery of state.json | PASS |  |
| A25 | guard hook blocks invoking the approval hook from a tool | PASS |  |
| A26 | guard hook allows pre-approval strategy artifacts | PASS |  |
| A27 | guard hook blocks edits to the client codebase before approval | PASS |  |
| A28 | ambiguous "approve ... but" is NOT approval | PASS |  |
| A29 | REVISE recorded from user prompt | PASS |  |
| A30 | revision routes back to owning state only (ARCHITECTURE), architect reset | PASS |  |
| A31 | APPROVE after blueprint changed post-presentation -> STALE, not approved | PASS |  |
| A32 | user APPROVE recorded by hook only, bound to blueprint hash | PASS |  |
| A33 | guard allows copy after approval | PASS |  |
| A34 | post-approval blueprint tampering blocks PRODUCTION | PASS |  |
| A35 | WAITING_FOR_APPROVAL -> PRODUCTION (v1) | PASS |  |
| A36 | PRODUCTION exit refused: untagged numeric claim, untagged quote, placeholder, tag leaked into markup | PASS |  |
| A37 | PRODUCTION -> CRITIQUE once copy validates (internal copy gate) | PASS |  |
| A38 | CRITIQUE -> VERIFICATION | PASS |  |
| A39 | engine recomputes verdict: 5 stated FAILs + criterion 24 overridden (guardrail UNDEFINED) = 19/25 -> DO_NOT_SHIP | PASS |  |
| A40 | COMPLETE refused on DO_NOT_SHIP | PASS |  |
| A41 | VERIFICATION -> ITERATION 1 (no user prompt), version v2 | PASS |  |
| A42 | ITERATION exit refused without a routing entry in ITERATION_LOG | PASS |  |
| A43 | ITERATION 1 -> PRODUCTION; production agents reset to pending | PASS |  |
| A44 | CRITIQUE refused: builder did not log the fix (build-notes stale) | PASS |  |
| A45 | VERIFICATION refused: critic did not re-run this iteration | PASS |  |
| A46 | ITERATION refused: verifier did not re-run this iteration | PASS |  |
| A47 | VERIFICATION -> ITERATION 2 | PASS |  |
| A48 | strategic failure routed to ARCHITECTURE invalidates approval | PASS |  |
| A49 | guard re-locks production while approval is invalidated | PASS |  |
| A50 | re-approval via /lp-approve -> PRODUCTION keeps version v3 | PASS |  |
| A51 | VERIFICATION -> ITERATION 3 | PASS |  |
| A52 | 4th iteration refused: hard cap -> BLOCKED (MAX_ITERATIONS), exit 3 | PASS |  |
| A53 | stop message: "Maximum autonomous iterations reached. The following issues remain..." | PASS |  |
| A54 | RESUME refused until the user extends | PASS |  |
| A55 | user EXTEND raises cap; RESUME -> VERIFICATION | PASS |  |
| A56 | NA on a non-NA criterion (1) is converted to FAIL | PASS |  |
| A57 | criterion 24 PASS overridden while LTV guardrail UNDEFINED | PASS |  |
| A58 | experiment proposed without guardrail = critical -> DO_NOT_SHIP | PASS |  |
| A59 | guardrail DEFINED only with numeric PROMOTE/KILL plan | PASS |  |
| A60 | all criteria pass + guardrail defined -> SHIP 25/25 | PASS |  |
| A61 | COMPLETE refused without FINAL_REPORT.md | PASS |  |
| A62 | VERIFICATION -> COMPLETE (final_status SHIP) | PASS |  |
| A63 | COMPLETE is terminal | PASS |  |
| A64 | all 13 states visited in scenario A | PASS | missing:  |
| B01 | NOT_QUALIFIED blocks research and tells orchestrator to consult user | PASS |  |
| B02 | cannot resume a NOT_QUALIFIED block without a user decision | PASS |  |
| B03 | user decision (proceed with caveats) -> resume to DISCOVERY | PASS |  |
| B04 | no baseline -> exact required sentence | PASS |  |
| B05 | no baseline -> no target value invented | PASS |  |
| B06 | low traffic -> INSUFFICIENT_TRAFFIC with exact sentence | PASS |  |
| B07 | guardrail cannot be DEFINED without a written PROMOTE/KILL plan | PASS |  |
| B08 | experiment readiness NOT_READY without guardrail | PASS |  |

## Scenario A final board

```
LANDING PAGE CRO SYSTEM
Project:        Lumen Sleep Mask (hypothetical) (lumen-sleep-mask)
URL:            https://lumen-sleep.test/products/weighted-mask
Current phase:  COMPLETE
Version:        v4   Iteration: 3/4
Approval:       APPROVED
Agents:
  âœ“ discovery
  âœ“ customer-intelligence
  âœ“ platform-analysis
  âœ“ competitive-intelligence
  âœ“ cro-auditor
  âœ“ positioning
  âœ“ conversion-strategist
  âœ“ page-architect
  âœ“ USER APPROVAL GATE
  âœ“ copywriter
  âœ“ designer
  âœ“ builder
  â—‹ cro-critic
  â—‹ verifier
```