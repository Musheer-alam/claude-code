---
name: information-architecture
description: LP-CRO information architecture method — derive sections from ranked objections, proof requirements and awareness; give every section a job, message, objection, proof, CTA role, importance and placement reason; order by evidence (TLPC sequence is a reference, never a default); produce a mobile-first low-fi wireframe spec.
---

# Skill: Information Architecture

## Purpose
Every section must have a job (P8); structure must be justified by this project's evidence (P18).

## Inputs
Archetype; strategy (job, message, ranked objections, proof map, hypotheses); positioning (wrong-fit rule, risk reversal, discount rules); customer awareness/sophistication; data (scroll depth, device split, traffic temperature); audit preserve list.

## Process
1. **Derive candidate sections** from needs, not from a template: recognition of the problem/outcome; commercial choice (offer/pack); legitimacy (credentials/volume); self-qualification (who it's for / not for); mechanism; substantiation (ingredients/spec/data); social proof (quantified, sourced); differentiation; objection clearance (FAQ); risk reversal; secondary conversion; compliance/footer. Add or drop based on the objection list.
2. **Section jobs**: for each — job, message, objection discharged, proof required (IDs or GAP), CTA role, importance (1–5), reason for placement, hypotheses served.
3. **Order** with explicit rules:
   - First mobile viewport: headline (core message), primary CTA, ≥1 proof element, offer cue.
   - Low awareness → recognition + mechanism earlier; high awareness/hot traffic → offer earlier.
   - Top-ranked objection is discharged before the second CTA appears.
   - Legitimacy before persuasion where trust is a top objection (TLPC OBSERVED: proof within first two screens, 4/4 pages).
   - Self-qualification before mechanism when wrong-fit buyers are a material risk (TLPC OBSERVED on the two highest-attribution pages) — otherwise later or omitted with reason.
   - Category differentiation after need is established when buyers are problem-aware but not brand-aware.
4. **Compare** with the TLPC-observed sequence (symptom → commercial choice → legitimacy → self-qualification → mechanism → substantiation → social proof → differentiation → objection clearance → compliance) and record each deviation's reason.
5. **Cut** sections with no job; list them with reasons.
6. **Wireframe spec**: mobile canvas 360–414px; per-section slots and relative weight; sticky CTA; accordions for FAQ; form handoff ≤4 inputs per view (multi-step over long forms); desktop deltas only where needed.

## Decision rules
- One primary CTA destination across all CTA instances.
- A secondary conversion appears after the main objection blocks, not in the hero.
- If proof for a placement requirement is a GAP, the section remains but the blueprint must flag the gap for the user.

## Outputs
`08-architecture/page-map.md`, `section-jobs.md`, `wireframe-spec.md`.

## Failure conditions
Strategy contains competing core messages → return to strategist (don't architect around it).

## Quality checks
- [ ] Every section has job + objection/hypothesis link
- [ ] First viewport spec includes headline, CTA, proof, offer cue
- [ ] Order rationale per section; deviations from reference explained
- [ ] Excluded sections listed
