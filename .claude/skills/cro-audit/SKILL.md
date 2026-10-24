---
name: cro-audit
description: LP-CRO existing-page diagnosis method — evidence-chained findings (Observation → Evidence → Problem → Conversion consequence → Hypothesis → Recommendation) across 18 audit areas, and a ranked P0–P3 conversion-leak inventory.
---

# Skill: CRO Audit

## Purpose
Diagnose, don't decorate. Every major finding is a causal chain tied to project evidence.

## Inputs
Live page + snapshots; discovery; customer intelligence & verbatims; platform analysis; competitive intelligence.

## Process
1. **As-is capture** (mobile first): section order; first-viewport inventory (headline, sub, CTA, proof, offer cue, visual); number of distinct messages above the fold; CTA count and destinations; forms (fields, steps, errors); proof (type, quantified?, sourced?); offer & AOV architecture (packs, bundles, subscription, shipping threshold); risk reversal; secondary conversion; wrong-fit filtering; load signals (page weight, LCP proxy, layout shift), console errors.
2. **Audit areas** (each addressed or N/A with reason): Hero · Message clarity · Audience clarity · Offer · Proof · Trust · Objections · CTA · Page hierarchy · Cognitive load · Mobile UX · Speed · Forms · Risk reversal · Secondary conversion · AOV architecture · Ad-to-page message match · Wrong-fit filtering.
3. **Findings** in the chain format, e.g.
   - Observation: hero describes the product category.
   - Evidence: 14/41 verbatims describe the symptom in situation language [V-…]; hero uses none [E-4xx].
   - Problem: message–market mismatch.
   - Consequence: visitors may not recognise relevance in the first seconds; matters more for cold traffic (62% of sessions, [E-2xx]).
   - Hypothesis: a customer-language problem/outcome hero improves message match → H-candidate.
   - Recommendation: replace category-first hero with problem/outcome-first messaging.
4. **Rank leaks**: severity from impact (how many visitors, how close to conversion), confidence (evidence strength), reach (mobile share etc.). P0 = blocks/breaks conversion or misleads (broken CTA, false claim, unusable mobile form); P1 = major persuasion gap on a top objection or message mismatch on majority traffic; P2 = meaningful friction; P3 = polish.
5. **Preserve list**: elements with evidence of working (high engagement, frequently praised, matching ads).

## Decision rules
- No project evidence → label HEURISTIC, cap at P2.
- Do not write replacement copy; describe the change.
- Distinguish page problems from offer/business problems (e.g. price too high vs. value not communicated) and flag the latter for positioning.

## Outputs
`05-audit/existing-page-audit.md`, `05-audit/conversion-leak-inventory.md`, evidence E-400–E-499.

## Failure conditions
Page not renderable → audit snapshots only and state it; none → BLOCKED.

## Quality checks
- [ ] All 18 areas covered
- [ ] Every P0/P1 has project evidence
- [ ] Mobile verified in a mobile viewport
- [ ] Leak inventory ranked with linked findings/hypotheses
- [ ] Preserve list present
