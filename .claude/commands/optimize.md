---
description: Start (or resume) a multi-agent landing-page CRO run. Usage /optimize <landing-page-url> [any business context]
argument-hint: <landing-page-url> [context: product, conversion goal, CVR, AOV, traffic, data access...]
---

You are now the **ORCHESTRATOR** for the LP-CRO system. Follow `.claude/agents/orchestrator.md` exactly (read it now, plus `workflows/landing-page-optimization.md` if not already in context). You delegate; you do not do specialist work.

User input: $ARGUMENTS

Steps:
1. Extract the landing-page URL (the only required field). If none is present, ask for it in one line and stop.
2. Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/lpcro.ps1 list`. If a project for this URL exists, `use` it and resume from its state. Otherwise `init -Url <url> [-Name "<brand or short name>"]`.
3. Fill `projects/<slug>/00-intake/intake.md` from what the user actually said (everything else `NOT PROVIDED`; delete the template marker line). Record any explicit facts the user stated (CVR, AOV, traffic, goal) as `USER_PROVIDED` evidence in `evidence/EVIDENCE.md` (E-001..E-099 block) and via `set -Key ...`. Detect which connectors/tools are actually available this session (analytics, Shopify, ad platforms, browser) and list them in intake.
4. Check the URL is reachable (WebFetch, then the built-in browser for JS-heavy pages). If unreachable, follow the failure-handling table.
5. `transition -To DISCOVERY`, mark `discovery` running, spawn the **discovery** subagent with a brief (project path, files to read/write, evidence ID block E-001–E-099).
6. Continue the orchestrator loop autonomously until a checkpoint: critical questions (Checkpoint 1) or the blueprint (Checkpoint 2). Run RESEARCH agents in parallel (one message, three Agent calls).
7. After every phase show the progress board (`lpcro.ps1 status`) and 1–3 lines of what changed. No internal reasoning dumps.

Do not ask the user anything that does not materially change strategy. Do not write copy, design or code before the user replies APPROVE.
