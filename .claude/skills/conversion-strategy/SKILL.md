---
name: conversion-strategy
description: LP-CRO conversion strategy method — one page, one primary job, one core message; ranked objections; proof requirements; primary and secondary CTA; cut/demote list; hypothesis registry (H-nnn) with mechanism, metric, guardrails and confidence.
---

# Skill: Conversion Strategy

## Purpose
Turn research into a strategy that can be built, critiqued and measured. (P7, P11 — TLPC VERIFIED "one thing the page must say".)

## Inputs
Discovery, customer, data, market, audit, positioning; conflicts register; state (baseline, feasibility, guardrail).

## Process
1. **The one job**: primary conversion (the action), primary audience (named in customer terms), traffic temperature. Everything else is secondary.
2. **Core message**: one sentence that a cold visitor could repeat. Test: does it survive the substitution test? is it provable?
3. **Core promise & mechanism**: what outcome, why believable (evidence IDs).
4. **CTAs**: primary (outcome-named, single destination); secondary soft conversion for the unready (quiz, consult, sample, guide, email) — must not compete visually or in message.
5. **Ranked objections**: score = frequency (VOC counts) × severity (deal-breaker?) × proximity (blocks at the CTA?). Top 5–8 ranked; each assigned where it will be discharged and with what proof.
6. **Proof requirements**: for each claim/objection, available proof (ID) or GAP. Gaps → ask the user (blueprint) or weaken the claim.
7. **Message hierarchy**: 1 core + ≤3 supporting. Everything else: cut or demote (FAQ/below fold), with reasons. If the business insists on many "must-say" messages, show the cut list in the blueprint.
8. **Hypotheses**: from P0/P1 leaks and strategic choices. Each H-nnn: problem, evidence, change, reason, expected mechanism, primary metric, guardrails, confidence, status UNTESTED. Rank by expected impact × confidence × ease.
9. **Conflicts**: any OPEN conflict affecting strategy must be resolved on evidence (hierarchy) or escalated before leaving STRATEGY.

## Decision rules
- Two candidate core messages with similar evidence → choose the one closest to the top verbatim theme and the dominant traffic's ad promise; log the alternative as a test hypothesis rather than putting both on the page.
- Proof before persuasion: where trust/legitimacy is a top objection, proof is a placement requirement for the architect.
- Never set a goal in percentage points; targets are relative.

## Outputs
`07-strategy/conversion-strategy.md`, `07-strategy/conversion-hypotheses.md`, `hypotheses/HYPOTHESES.md` entries, plus `07-strategy/experiment-plan.md` via the experimentation skill.

## Failure conditions
No primary conversion agreed → cannot proceed (orchestrator CRITICAL question). Unresolvable conflict → leave OPEN and report.

## Quality checks
- [ ] Exactly one primary conversion and core message
- [ ] Ranked objections with scoring rationale
- [ ] Proof gaps explicit
- [ ] Cut/demote list
- [ ] Every hypothesis complete with Status
- [ ] `lpcro.ps1 validate` passes
