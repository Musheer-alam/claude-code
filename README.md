# LP-CRO — multi-agent landing-page CRO workflow for Claude Code

Give it a landing-page URL. A team of 13 specialist subagents, driven by an orchestrator, researches the business, customer, data and market. It then diagnoses the current page, builds positioning, strategy and an evidence-backed architecture, and **stops for your approval**. After you approve, it writes, designs, builds, critiques and verifies the page, iterating at most 3 times on its own.

## Quick start
1. Open this folder in Claude Code (a new session, so the hooks in `.claude/settings.json` load; approve them in `/hooks` if asked).
2. Run: `/optimize https://your-site.com/landing-page` and add any context you have (goal, CVR, AOV, traffic, data access, brand assets, codebase path).
3. Answer only the critical questions it asks.
4. Review the blueprint and reply **APPROVE**, **REVISE …**, **ASK QUESTIONS** or **START OVER**.
5. Production runs on its own until SHIP, or until it stops with an honest list of unresolved issues.

`/lp-status` shows the board at any time. Everything for a run lives in `projects/<slug>/`.

## How it is built
- `CLAUDE.md` — operating rules for every session
- `workflows/` — state machine (human-readable + JSON enforced by the engine)
- `.claude/agents/` — orchestrator protocol + 13 specialists
- `.claude/skills/` — 16 method skills
- `.claude/commands/` — `/optimize`, `/lp-status`, `/lp-approve`, `/lp-revise`, `/lp-extend`
- `scripts/lpcro.ps1` — state engine (gates, evidence validator, verdict scoring, sample-size math)
- `scripts/hooks/` — approval capture (user-typed only), production write guard, session resume
- `templates/project/` — artifact templates; `schemas/` — formats
- `rules/PRINCIPLES.md`, `reference/tlpc-methodology.md` — methodology with provenance grades

## Verify the machinery
```
powershell -NoProfile -ExecutionPolicy Bypass -File tests/simulate.ps1
```
This runs a hypothetical project through all 13 states, the approval gate, the iteration cap and the engine overrides. Results go to `tests/SIMULATION_REPORT.md`. The 12 design checks are in `tests/SELF_INSPECTION.md`.

The "≥20% improvement" is an **optimisation target measured relatively** (2.0% → 2.4%). It is never a promise. Results count as validated only after a pre-registered experiment read with LTV guardrails.
