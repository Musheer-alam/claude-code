---
name: conversion-copy
description: LP-CRO evidence-bound conversion copywriting — hero from verbatims, one core message, explicit objection handling, quantified proof only from the evidence registry, inline [E-nnn]/[V-nnn] tags for every numeric claim and quote, claim ledger, no generic AI copy.
---

# Skill: Conversion Copy

## Purpose
Production-ready copy that sounds like the customer and claims only what the project can prove. (P4, P9, P10, P11 — TLPC VERIFIED: "real copy" before design; hero from the customer's mouth; "no testimonials until there's a number next to them".)

## Inputs
Verbatim bank, customer intelligence, positioning, strategy, page map/section jobs/wireframe, evidence registry, competitor overused phrases.

## Process
1. **Read the approved page map** — sections and order are fixed.
2. **Hero**: draft ≥3 options, each derived from a named verbatim theme (V-IDs); pick by: matches top theme + top ad promise, passes substitution test, provable. Subheadline: who it's for + mechanism/outcome + proof cue.
3. **Write each section to its job** — headline states the section's message; body discharges its objection; proof sits next to the claim it supports.
4. **Proof**: use numbers only from E-/V- entries (ratings with counts and dates, study results with source, volumes as displayed by the business marked as the business's claim if unaudited). Testimonials only as exact verbatims with `Usable in public copy: YES`: `> "…" — <first name/initial, context if in source> [V-nnn]`.
5. **Objections**: every ranked objection answered in-section or in FAQ with a direct, specific answer (no deflection).
6. **Expectation-setting**: time-to-result, usage requirements, fit limits — stated before the CTA where relevant (suppresses returns).
7. **Risk reversal & offer**: only real terms, with numbers tagged.
8. **CTA**: outcome-named, consistent; microcopy under CTA handles the last-second fear (shipping, cancellation, payment).
9. **Secondary conversion** copy and **final CTA**.
10. **Ledgers**: claim ledger, customer-language trace, objection coverage, claims not made.
11. Run `lpcro.ps1 validate`; fix all errors.

## Decision rules
- If the evidence supports "4.6★ from 1,240 reviews (site, Oct 2026)" write that — not "loved by thousands".
- If a desirable claim lacks evidence: don't make it; list it under "claims not made" (it becomes a proof-gathering recommendation).
- Regulated categories (health, finance, legal): no cure/treat/guarantee-of-outcome language; mirror only what evidence and the brand's compliant claims allow.
- Banned filler: unlock, elevate, seamless, revolutionary, game-changer, next-level, world-class, best-in-class (unless sourced), "we're passionate about".
- Specific beats clever. Customer phrasing beats category phrasing. One idea per sentence on mobile.

## Outputs
`09-copy/final-copy.md`.

## Failure conditions
Approved architecture can't be honoured with available proof → report to orchestrator (do not restructure).

## Quality checks
- [ ] `validate` passes
- [ ] Hero traced to V-ID; passes substitution test
- [ ] Every ranked objection covered
- [ ] No banned filler; no untagged numbers; no invented quotes
- [ ] CTA outcome-named
