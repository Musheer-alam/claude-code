---
name: evidence-management
description: LP-CRO evidence discipline used by every agent — register claims in evidence/EVIDENCE.md (E-nnn) with source, grade and confidence; cite IDs wherever claims are used; use UNKNOWN / NOT AVAILABLE / NOT VERIFIED / INSUFFICIENT DATA instead of guessing; resolve conflicts by source hierarchy; pass the lpcro.ps1 validator.
---

# Skill: Evidence Management

## Purpose
Make every strategic, copy and design decision traceable — and make fabrication mechanically hard. (P9; SYS.)

## Inputs
Anything you observed, measured, read or were told.

## Process
1. **Before writing a claim**, ask: where did this come from? If you can't cite it, it's UNKNOWN / NOT VERIFIED / an INFERENCE (graded as such).
2. **Register** in `evidence/EVIDENCE.md` using the format in `schemas/registry-formats.md`, inside your agent's ID block — or, if you run in a parallel state (customer-intelligence, platform-analysis, competitive-intelligence, cro-auditor, positioning), in your own shard `evidence/shards/<your-agent-name>.md` so parallel agents never edit the same file. Read the registry (and your shard) first to find the next free ID in your block. Append; never rewrite others' entries. Correct by adding a superseding entry ("Supersedes E-nnn").
3. **Grade** the claim: VERIFIED (directly stated/measured in a primary source) · OBSERVED (seen repeatedly) · INFERRED (reasoned) · UNKNOWN. Confidence: HIGH/MEDIUM/LOW.
4. **Cite** `[E-nnn]` / `[V-nnn]` / `H-nnn` in your artifact wherever the claim is used.
5. **Site claims** (e.g. "50,000+ customers" on the brand's own page) are registered as "Brand claims X" — grade OBSERVED, Source the URL — and copy may repeat them only as the brand's claim, never upgraded to verified fact.
6. **User statements** are USER_PROVIDED evidence ("User, chat <date>"), confidence per specificity.
7. **Conflicts**: if your evidence contradicts an existing entry or another agent's conclusion, don't overwrite — report it in your handoff CONFLICTS line; the orchestrator opens a C-nnn. Hierarchy: 1 behavioural data · 2 customer interviews · 3 first-party analytics · 4 primary sources · 5 repeated observed patterns · 6 inference · 7 generic marketing assumptions (never sufficient alone).
8. **Validate**: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/lpcro.ps1 validate` (if your tools allow) — fix dangling IDs, missing sources, untagged numeric claims.

## Decision rules
- Generic best practice ("CTAs above the fold convert better") is never evidence for a project claim; label HEURISTIC.
- TLPC dossier content is a methodological reference (`reference/tlpc-methodology.md`), never evidence about this project; TLPC numbers are never cited as expectations.
- Absence of evidence is recorded, not filled.

## Outputs
Registry entries; citations in your artifacts.

## Failure conditions
Validator errors block the workflow's next transition; fix them before handing off.

## Quality checks
- [ ] Every number/quote in my artifact has an ID
- [ ] IDs within my block, sequential, defined
- [ ] Grades honest (nothing INFERRED labelled VERIFIED)
- [ ] Validator passes
