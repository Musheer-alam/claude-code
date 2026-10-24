# Evidence Registry

> Shared by all agents. Append-only (correct by adding a superseding entry, never by silent edits). IDs are sequential (E- followed by three digits). Before adding, read the last ID in this file. `lpcro.ps1 validate` fails on any `[E-xxx]` reference that is not defined here, and on entries with no Source or no Confidence.
>
> Grades follow the TLPC dossier convention and apply to the CLAIM, not the source:
> VERIFIED (directly stated/measured in a primary source) · OBSERVED (seen repeatedly) · INFERRED (reasoned, not proven) · UNKNOWN.
> Source hierarchy for conflicts: 1 direct behavioural data · 2 direct customer interviews · 3 first-party analytics · 4 primary-source evidence · 5 repeated observed patterns · 6 inference · 7 generic marketing assumptions (never sufficient alone).

<!--
### E-XXX
- **Claim:** one sentence
- **Source:** URL + access date / tool + report + date range / file + location / "User, chat message <date>"
- **Source type:** BEHAVIOURAL_DATA | INTERVIEW | FIRST_PARTY_ANALYTICS | PRIMARY_SOURCE | OBSERVED_PATTERN | INFERENCE | USER_PROVIDED | THIRD_PARTY
- **Evidence:** the exact quote / number / observation
- **Grade:** VERIFIED | OBSERVED | INFERRED | UNKNOWN
- **Agent:** who registered it
- **Confidence:** HIGH | MEDIUM | LOW
- **Used by:** Strategy, Architecture, Copy, ...
-->
