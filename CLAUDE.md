# LP-CRO — Multi-Agent Landing Page CRO & Reconstruction System

This repository is a reusable Claude Code workflow. Given a landing-page URL (plus any optional context), a coordinated team of specialist subagents researches the business, customer, data and market; diagnoses the existing page; builds positioning, a conversion strategy and an evidence-backed page architecture; **stops for user approval**; then writes copy, designs, builds, critiques, verifies and iterates (max 3 autonomous iterations).

Start a run with: **`/optimize <landing-page-url> [any context]`**. Check progress with `/lp-status`.

## Who does what

- **The main session is the ORCHESTRATOR** (protocol: `.claude/agents/orchestrator.md`). Subagents cannot spawn subagents, so orchestration never runs as a subagent. The orchestrator delegates; it does not do specialist work (no research, copy, design or code itself). It may compile the blueprint, the iteration log and the final report from specialists' artifacts.
- **Specialists** are subagents in `.claude/agents/` (13 of them). Each reads its skill in `.claude/skills/<name>/SKILL.md`, writes its artifacts under `projects/<slug>/`, and returns a short handoff report (`schemas/handoff.md`).
- **The engine** `scripts/lpcro.ps1` owns state. It enforces legal transitions, required artifacts, evidence traceability, the approval gate, verdict scoring and the iteration cap. Never edit `state.json` or `PROJECT_STATE.md` by hand (a hook blocks it).
- **Hooks** (`.claude/settings.json`): `guard.ps1` blocks production writes before approval and direct state edits; `capture-decision.ps1` is the only thing that can record approval, and only from the user's own typed reply; `session-status.ps1` prints the active project's board at session start.

Engine invocation (Windows PowerShell 5.1; no Python/Node required):
```
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/lpcro.ps1 <command> [options]
```
Key commands: `init -Url`, `status`, `next`, `transition -To <STATE>`, `agent -Agent <a> -Status <s>`, `question -Text .. [-Critical]`, `question -Resolve Q-001 -Answer ..`, `set -Key .. -Value ..`, `baseline ..`, `guardrail ..`, `validate`, `verdict`. Run `scripts/lpcro.ps1 help` for all.

## Non-negotiables (apply to every agent)

1. **Evidence over assumption.** Every important claim is registered in `evidence/EVIDENCE.md` (E-xxx) with source and confidence, and cited where used. Unknowns are written as `UNKNOWN`, `NOT AVAILABLE`, `NOT VERIFIED` or `INSUFFICIENT DATA` — never filled with plausible guesses.
2. **No fabrication.** No invented quotes, testimonials, statistics, reviews, certifications, results, or interviews. If interviews did not happen, write `INTERVIEW DATA: NOT AVAILABLE`. Quotes live in `02-customer/verbatim-bank.md` (V-xxx) with a citable source.
3. **Target ≠ result.** "≥20% RELATIVE improvement" is an optimisation TARGET (2.0% → 2.4%, not 22%). Nothing is called a win until a pre-registered experiment read says so. If there is no baseline or too little traffic, say so in the exact words in `workflows/landing-page-optimization.md` §7.
4. **LTV over raw CVR.** No experiment is "ready" without a PROMOTE/KILL rule recorded before launch. Without the data: `LTV GUARDRAIL: UNDEFINED` and ask the user.
5. **One page → one primary job → one core message.**
6. **Approval gate.** No copy, design, build, critique or verification artifact — and no change to the client codebase — before the user replies **APPROVE** to the blueprint. Approval made by anything other than the user's own message is void.
7. **Independence.** The cro-critic and verifier never fix what they review; the builder never scores its own work.
8. **Ask only what matters.** A question to the user must name the downstream decision it changes. Everything else proceeds with the gap recorded.
9. **TLPC is a reference, not a template.** `reference/tlpc-methodology.md` grades every borrowed idea (VERIFIED / OBSERVED / INFERRED). Decisions are tagged TLPC VERIFIED / TLPC OBSERVED / TLPC INFERRED / SYSTEM IMPROVEMENT / PROJECT-SPECIFIC DECISION. Never present an inferred TLPC practice as fact.

## Map

| Path | Purpose |
|---|---|
| `workflows/landing-page-optimization.md` | Complete state machine, gates, failure handling, conflict rules, output experience |
| `workflows/state-machine.json` | Machine-readable state machine (engine + orchestrator read it) |
| `.claude/agents/` | 14 agent definitions (orchestrator protocol + 13 specialists) |
| `.claude/skills/` | 16 reusable skills (method per discipline) |
| `.claude/commands/` | `/optimize`, `/lp-status`, `/lp-approve`, `/lp-revise`, `/lp-extend` |
| `rules/PRINCIPLES.md` | The 18 methodological principles, with provenance and when each applies |
| `reference/tlpc-methodology.md` | Evidence-graded digest of the TLPC reverse-engineering dossier |
| `schemas/` | JSON schemas (state, verdict) and markdown entry/handoff formats |
| `templates/project/` | Artifact templates copied into every new project |
| `projects/<slug>/` | One folder per optimisation run (all spec paths like `/01-discovery/…`, `/PROJECT_STATE.md`, `/evidence/EVIDENCE.md` are relative to this folder) |
| `scripts/` | Engine, hooks, shared library |
| `tests/simulate.ps1` | End-to-end state-machine simulation on a hypothetical project |

## Context discipline

Agents communicate through artifacts, not conversation. A specialist returns ≤250 words in the handoff format; the orchestrator passes the next agent **paths and a short brief**, never another agent's full output. Re-read files instead of relying on memory; `PROJECT_STATE.md` is the resumable source of truth.

## Template marker

Every templated artifact starts with `<!-- LPCRO:TEMPLATE -->`. The engine treats a file as unwritten while that line is present. Agents delete it when they fill the file.
