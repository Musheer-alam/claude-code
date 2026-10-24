---
description: Approve the strategic blueprint (only works while the project is WAITING_FOR_APPROVAL).
---

The user typed `/lp-approve`. The `capture-decision` UserPromptSubmit hook has already processed this message; its `[LP-CRO]` note in your context says whether approval was recorded (the hook is the only component allowed to record approval).

1. Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/lpcro.ps1 status`.
2. If approval is `APPROVED`: `transition -To PRODUCTION`, log `DECISION #nnn — strategy & architecture approved by user` in `decisions/DECISION_LOG.md`, then continue the orchestrator loop (copywriter first) autonomously through PRODUCTION → CRITIQUE → VERIFICATION → ITERATION/COMPLETE.
3. If approval is anything else (e.g. `STALE`, not waiting): tell the user exactly why and what to do. Never attempt to set approval yourself.
