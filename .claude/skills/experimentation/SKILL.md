---
name: experimentation
description: LP-CRO experimentation & measurement method — baseline, ≥20% RELATIVE improvement target (not percentage points), sample-size/duration feasibility, pre-registered decision rules, CVR+AOV+RPV+return+repeat+LTV tracking, and LTV/wrong-win PROMOTE/KILL guardrails recorded before launch. Distinguishes TARGET from VALIDATED RESULT.
---

# Skill: Experimentation

## Purpose
Close the gap the TLPC dossier identified: no public experimentation system, significance thresholds, sample-size method or audited results. (P16, P17 — SYS.)

## Inputs
Baseline (state + platform analysis), traffic, positioning guardrail proposal, hypotheses.

## Process
1. **Baseline** — from `PROJECT_STATE.md` (recorded by `lpcro.ps1 baseline`). Copy value, definition, source, window.
2. **Target** — relative: `target = baseline × 1.20`. Always show the worked example with the actual baseline (2.0% → 2.4%; **not** 22%, **not** +20 pp).
3. **Feasibility** — Lehr approximation for a two-arm test at α = 0.05 (two-sided), power 0.8:
   `n_per_arm ≈ 16 · p(1−p) / (0.2·p)²`. Example p = 0.02 → ≈ 19,600 sessions per arm. Weeks = 2n ÷ weekly sessions. > 8 weeks ⇒ INSUFFICIENT_TRAFFIC. The engine computes this; quote it.
   - No baseline: write exactly "20% improvement cannot currently be validated because a reliable baseline is unavailable."
   - Insufficient traffic: write exactly "20% improvement cannot currently be statistically validated with available traffic."
4. **Design** — A/B split preferred (name the tool or NOT AVAILABLE); otherwise sequential before/after with confounds logged (spend, creative, promos, seasonality, stock) and labelled DIRECTIONAL. Full weeks; ≥1 business cycle; fixed horizon; no stopping on peeks.
5. **Metrics** — primary CVR (pre-registered definition); secondary AOV, revenue per visitor; quality guardrails return/refund/RTO rate, repeat rate, LTV (30/60/90-day reads).
6. **LTV / wrong-win guardrail** — before launch, numeric:
   - PROMOTE: CVR up per decision rule AND AOV not down > X% AND return rate not up > Y pp AND repeat/LTV proxy not down > Z%.
   - KILL: CVR up BUT return rate up > Y pp OR LTV proxy down > Z% OR AOV down > X%.
   - HOLD: mixed → extend to next read.
   Thresholds come from the user's economics; without them: `LTV GUARDRAIL: UNDEFINED`, list the inputs needed (current return rate, AOV, margin, repeat rate, acceptable trade-offs) and the experiment stays NOT_READY.
7. **Instrumentation** — events and parameters the builder must implement; UTM conventions; variant assignment logging.
8. **Statuses** — hypotheses UNTESTED → TESTING (live) → VALIDATED/REJECTED only after the pre-registered read. Pre-launch language is always TARGET.

## Decision rules
- CVR alone never promotes a variant.
- Never report a relative lift without the absolute values beside it.
- Never call a before/after comparison "significant".

## Outputs
`07-strategy/experiment-plan.md` (strategist); sections of `FINAL_REPORT.md` (measurement, experiment, baseline vs target, guardrails).

## Failure conditions
No baseline and no traffic data → plan focuses on instrumentation and baseline capture first (2–4 weeks pre-launch), with the exact NO_BASELINE sentence.

## Quality checks
- [ ] Relative target with worked example
- [ ] Feasibility sentence matches engine status
- [ ] PROMOTE/KILL numeric or UNDEFINED with data request
- [ ] TARGET vs VALIDATED wording correct throughout
