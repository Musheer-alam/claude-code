---
description: Allow more autonomous iterations after the 3-iteration limit was reached. Usage /lp-extend [1-3]
argument-hint: [number of extra iterations, 1-3]
---

The user typed `/lp-extend $ARGUMENTS`. The `capture-decision` hook raises the iteration cap only if the project is BLOCKED on MAX_ITERATIONS; its `[LP-CRO]` note says whether it did.

If extended: `transition -To RESUME`, then continue the iteration loop (ITERATION → PRODUCTION → CRITIQUE → VERIFICATION) per `workflows/landing-page-optimization.md` §6, focusing first on the unresolved issues that were reported. If not extended, explain why.
