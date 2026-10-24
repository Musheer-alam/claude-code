---
name: qa
description: LP-CRO final verification gate — score the built page on 25 PASS/FAIL/NA criteria with measurable rules, evidence and fixes; detect critical failures; write verdict.json for the engine to recompute (SHIP 24–25, SHIP WITH FIXES 21–23, DO NOT SHIP <21 or any critical).
---

# Skill: QA / Final Verification

## Purpose
The independent ship/no-ship decision. Assume the builder failed until shown otherwise. (Criteria adapted from the dossier's reconstructed scorecard, which is itself a reconstruction — SYS.)

## Inputs
Rendered page (you render it), critic report (input only), all artifacts, state (baseline, guardrail, experiment readiness).

## Process
1. `lpcro.ps1 validate` — any error is a critical UNSUPPORTED_FACTUAL_CLAIM (the engine will add it anyway).
2. Render mobile (375×812) and desktop; measure load (navigation timing / LCP proxy), console errors, CTA behaviour.
3. Score each criterion with its rule:

| # | Criterion | PASS rule |
|---|---|---|
| 1 | Single message | Core claim writable in one sentence; no competing claim above the fold |
| 2 | Named audience | Page names/clearly signals who it's for, matching positioning |
| 3 | Customer-language problem | Problem statement traceable to verbatims (V-ID) |
| 4 | Differentiation | Hero/USP would read false on a named competitor's page |
| 5 | Offer clarity | Cold reader can state what, price/terms, next step within ~10s |
| 6 | Ranked objections | Strategy has a ranked list and the page follows that priority |
| 7 | Customer-language headline | Headline harvested (V-ID), not authored from the product sheet |
| 8 | Quantified proof | Proof carries numbers/outcomes/timeframes; no pure-praise testimonials (NA only if the business has no quantifiable proof — then flagged) |
| 9 | Explicit objection inventory | Every ranked objection answered on page (count) |
| 10 | Expectation setting | Time-to-result / usage / fit limits stated pre-CTA where relevant (NA with reason) |
| 11 | CTA clarity | Outcome-named, consistent, single primary destination |
| 12 | Mobile-first | Verified at mobile viewport in a real browser render; no horizontal scroll; targets ≥44px |
| 13 | Scannability | Headings alone tell the story |
| 14 | Friction redistributed | ≤4 inputs per view; multi-step over long-form (NA if no form) |
| 15 | Secondary conversion | Non-buyer has a defined next action (NA only if strategy justified none) |
| 16 | 2027 test | Proxy judgement: credible, current, consistent; recommend 5-person human test |
| 17 | Proof before first scroll | ≥1 credential/rating/volume figure in the initial mobile viewport |
| 18 | Hierarchy encodes priority | Most dominant element = highest-priority message |
| 19 | Component consistency | Repeated components share padding/edges/baselines |
| 20 | Mobile performance | Measured load acceptable (target LCP < 2.0s mobile; state method) |
| 21 | Baseline recorded | State has baseline value, or explicit UNAVAILABLE + pre-launch capture plan |
| 22 | Message match to ads | Top ad promise visible in hero (NA if no paid traffic, with reason) |
| 23 | Specific risk reversal | Guarantee/trial/returns stated with a number (NA only if business offers none — flagged as recommendation) |
| 24 | LTV kill rule | PROMOTE/KILL thresholds recorded before launch (state guardrail DEFINED) |
| 25 | Wrong-fit filter | Page says who it is not for / routes wrong-fit traffic (NA with reason) |

4. Critical failures: MISSING_CONVERSION_OBJECTIVE · UNSUPPORTED_FACTUAL_CLAIM · FABRICATED_TESTIMONIAL · MISSING_BASELINE_WHERE_DATA_EXISTS · BROKEN_PRIMARY_CTA · MAJOR_MOBILE_FAILURE · SERIOUS_ACCESSIBILITY_OR_FUNCTIONALITY · NO_LTV_GUARDRAIL_WITH_EXPERIMENT.
5. Write `verdict.json` (schema `schemas/verdict.schema.json`), run `lpcro.ps1 verdict`, and record the engine's verdict and overrides in `final-verification.md`.

## Decision rules
- Score = 25 − FAILs. 24–25 & no critical → SHIP · 21–23 & no critical → SHIP ONLY with named fix list · <21 → DO NOT SHIP · any critical → DO NOT SHIP.
- NA allowed only for 8, 10, 14, 15, 22, 23, 25 with a reason; the engine converts other NAs to FAIL.
- Each FAIL: criterion, evidence, fix, and route (copy/design/build/strategic).

## Outputs
`13-verification/final-verification.md`, `13-verification/verdict.json`, evidence E-950–E-999.

## Failure conditions
Unrenderable page → rendering criteria FAIL + critical.

## Quality checks
- [ ] 25 rows with evidence
- [ ] Engine verdict copied verbatim
- [ ] Fix list / unresolved list present as required
