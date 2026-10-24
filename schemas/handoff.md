# Agent → Orchestrator Handoff Report

Every specialist ends its run by returning **only** this block (≤250 words). Full detail lives in the artifacts. The orchestrator passes the next agent paths and a brief derived from this — never the raw output.

```
HANDOFF · <agent-name> · project <slug> · version <vN>
STATUS: DONE | PARTIAL | FAILED | BLOCKED
ARTIFACTS: <paths written/updated>
KEY FINDINGS (≤5 bullets, each with E-/V-/H- IDs)
EVIDENCE ADDED: E-xxx..E-yyy (count) · VERBATIMS: V-xxx..V-yyy · HYPOTHESES: H-xxx..
QUESTIONS FOR USER: <id-less list; each: question | decision it unlocks | CRITICAL or NICE-TO-HAVE>  (or NONE)
CONFLICTS: <claim that contradicts another agent's artifact, with both evidence IDs>  (or NONE)
DATA GAPS: <what was NOT AVAILABLE / UNKNOWN and its impact>
RISKS: <risks to strategy or claims>
CONFIDENCE: HIGH | MEDIUM | LOW — why
NEXT: <what the downstream agent most needs to know, ≤2 lines>
```

Rules: no quotes or numbers in the handoff that are not already in an artifact with an ID; no recommendations outside the agent's remit.
