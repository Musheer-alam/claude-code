---
name: cro-critique
description: LP-CRO independent adversarial critique — try to break the new page on strategy, copy, UX, design and CRO; 5-second test; claim-to-evidence spot-check; original-vs-new regression check; failures written as FAILURE → EVIDENCE → IMPACT → RECOMMENDATION → ROUTE.
---

# Skill: CRO Critique

## Purpose
Independent pressure-testing before the formal gate (P15; SYS: TLPC's QA was manual and functional; this adds a strategic critic).

## Inputs
Original page, new page, research, strategy, architecture, copy, hypotheses, evidence registry.

## Process
1. **Render** the new page at 375×812 first, then 1440. Screenshot first viewports.
2. **5-second test** (first mobile viewport only): What is it? Who is it for? Why believe it? What do I do next? Any answer missing → failure.
3. **Checklist**
   - Strategy: audience clear · core problem clear · promise clear · differentiation meaningful (substitution test against the competitor set) · page does one job (count competing CTAs/messages).
   - Copy: hero reflects customer language (trace to V-ID) · claims supported (spot-check ≥10 rendered claims → E-/V- IDs; report n checked / n failed) · proof quantified where possible · ranked objections handled (map each) · CTA clear (outcome-named) · hierarchy coherent.
   - UX: scannable (headings alone tell the story) · friction reduced (form inputs per view, steps) · mobile-first (thumb reach, tap targets, sticky CTA not obscuring) · secondary conversion present · path to conversion obvious.
   - Design: proof before first scroll · hierarchy encodes priority · supports conversion (no decoration outranking CTA) · credible (2027 test) · consistent components · fast (observe load; large images; layout shift).
   - CRO: baseline recorded (state) · ad-to-page message match · risk reversal specific · LTV guardrail defined · wrong-fit filter present.
4. **Break it**: keyboard-only; zoom 200%; slow network; images blocked; long product names; CTA destination resolves; forms with invalid input; console errors.
5. **Regression**: what did the original do better? (preserve list items lost, proof removed, speed worse).
6. **Write failures**: FAILURE → EVIDENCE → IMPACT → RECOMMENDATION → ROUTE TO (copywriter/designer/builder/strategist/architect), severity P0–P3.

## Decision rules
- Taste is not a failure; a failure needs a conversion consequence and evidence.
- Never fix; never edit other agents' files.
- A claim in markup with no registry entry is a P0 (unsupported factual claim).

## Outputs
`12-qa/cro-critic.md`, `12-qa/screenshots/`, evidence E-900–E-949.

## Failure conditions
Page cannot render → P0 and stop.

## Quality checks
- [ ] Rendered in both viewports
- [ ] Spot-check counts reported
- [ ] Regression section complete
- [ ] Every failure evidenced and routed
