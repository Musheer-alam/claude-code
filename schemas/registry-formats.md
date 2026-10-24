# Registry entry formats

The validator (`lpcro.ps1 validate`) parses these exact shapes: a level-3 heading with the ID, then `- **Field:** value` bullets. IDs are zero-padded to three digits. Registries are append-only.

## Evidence — `evidence/EVIDENCE.md`
```
### E-nnn
- **Claim:**
- **Source:**            (required; URL + access date, tool + report + range, file + location, or "User, chat <date>")
- **Source type:**       BEHAVIOURAL_DATA | INTERVIEW | FIRST_PARTY_ANALYTICS | PRIMARY_SOURCE | OBSERVED_PATTERN | INFERENCE | USER_PROVIDED | THIRD_PARTY
- **Evidence:**          exact quote / number / observation
- **Grade:**             VERIFIED | OBSERVED | INFERRED | UNKNOWN
- **Agent:**
- **Confidence:**        HIGH | MEDIUM | LOW   (required)
- **Used by:**
```
Agents in a parallel state (RESEARCH, DIAGNOSIS) write the same format to `evidence/shards/<agent-name>.md` instead; the orchestrator merges shards with `lpcro.ps1 merge-evidence` when the state completes.

ID blocks (avoid collisions between parallel agents): discovery/orchestrator 001–099 · customer 100–199 · platform 200–299 · market 300–399 · auditor 400–499 · positioning 500–599 · strategist 600–699 · architect 700–749 · copy/design/build 750–899 · critic/verifier 900–999.

## Verbatim — `02-customer/verbatim-bank.md`
```
### V-nnn
- **Quote:**  "exact words"
- **Source:**                 (required)
- **Source type:**            INTERVIEW | REVIEW | FORUM | SOCIAL | SUPPORT | SURVEY | COMPETITOR_REVIEW
- **Context:**
- **Theme:**
- **Confidence:**
- **Usable in public copy:**  YES | NO
```

## Hypothesis — `hypotheses/HYPOTHESES.md`
```
### H-nnn
- **Problem:**
- **Evidence:**
- **Change:**
- **Reason:**
- **Expected mechanism:**
- **Primary metric:**
- **Guardrail:**
- **Confidence:**   HIGH | MEDIUM | LOW
- **Status:**       UNTESTED | TESTING | VALIDATED | REJECTED   (required)
```

## Decision — `decisions/DECISION_LOG.md`
```
### DECISION #nnn
- **Decision:** · **Reason:** · **Evidence:** · **Alternatives considered:** · **Rejected because:** · **Agent:** · **User approval:** YES | NO | NOT REQUIRED · **Provenance:** TLPC VERIFIED | TLPC OBSERVED | TLPC INFERRED | SYSTEM IMPROVEMENT | PROJECT-SPECIFIC DECISION
```

## Conflict — `decisions/CONFLICTS.md`
```
### C-nnn
- **Status:** OPEN | RESOLVED | ESCALATED_TO_USER   (OPEN blocks leaving STRATEGY)
- **Position A:** · **Position B:** · **Which evidence has stronger support?** · **Resolution:** · **Decision logged as:**
```

## Inline citation in copy — `09-copy/final-copy.md`
- Any line with a number, %, price, count, duration or rating → `[E-nnn]` or `[V-nnn]` on the same line.
- Any quote/testimonial → blockquote line (`> "…"`) with `[V-nnn]`.
- The builder strips tags; tags in production markup fail validation.
