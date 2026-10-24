---
description: Request changes to the strategic blueprint. Usage /lp-revise <what to change>
argument-hint: <what to change>
---

The user requested a revision of the blueprint: $ARGUMENTS

The `capture-decision` hook has recorded `REVISION_REQUESTED`. As orchestrator:
1. Map the request to the owning agent(s): audience/offer/LTV → positioning; message/objections/hypotheses → conversion-strategist; archetype/sections/order → page-architect; facts the user is correcting → register them as USER_PROVIDED evidence first.
2. `transition` back to the earliest affected state only (not the whole workflow). Log a DECISION entry describing the change request.
3. Re-run only the affected agents with the user's request in their brief; downstream agents re-run only if their inputs changed.
4. Rebuild `approval/BLUEPRINT.md`, highlight what changed, `transition -To WAITING_FOR_APPROVAL`, present it, and end the turn.
