# Methodological Principles

Reusable rules, not page templates. Each has a provenance tag (from the TLPC dossier's grading, see `reference/tlpc-methodology.md`), the agents that apply it, and — critically — **when it does not apply**. Agents must decide per project whether a principle applies and log non-obvious calls as DECISIONs.

Provenance: **TLPC-V** = TLPC VERIFIED (stated in primary sources) · **TLPC-O** = TLPC OBSERVED (seen across pages) · **TLPC-I** = TLPC INFERRED · **SYS** = SYSTEM IMPROVEMENT (added where the dossier found TLPC weak or silent).

| # | Principle | Provenance | Applied by | Applies when | Does NOT apply / adapt when |
|---|---|---|---|---|---|
| P1 | **Qualify before building.** Establish the page has a real job, traffic and headroom before spending effort. | TLPC-V (application form, refusal list) | discovery, orchestrator | Always | Never skip; but a low-traffic page can still be QUALIFIED_WITH_CAVEATS (improve now, validate later) |
| P2 | **Research the customer before writing.** | TLPC-V (n≥5 interviews named) | customer-intelligence | Always | If no interviews: public VOC + explicit `INTERVIEW DATA: NOT AVAILABLE`; lower confidence |
| P3 | **Use quantitative platform data where available.** | TLPC-V (Meta/Shopify/GA/Clarity named) | platform-analysis | Any connected source | No data → say NOT AVAILABLE; never estimate figures |
| P4 | **Use customer language.** Situation-specific, first-person ("bloated after lunch") over category language ("gut health optimisation"). | TLPC-V (stated principle) | customer-intelligence, copywriter | Whenever verbatims exist | B2B/regulated categories may need adapted language; never fabricate a "verbatim" |
| P5 | **Know which buyer the page recruits.** Hero framing selects the customer. | TLPC-V (CRO Factor 01) | positioning | Always | — |
| P6 | **Consider LTV, not only CVR.** | TLPC-V as stated position; UNKNOWN whether practised | positioning, strategist, verifier | Repeat-purchase / subscription / high-return categories | One-off purchases: substitute refund/chargeback/RTO and lead-quality guardrails |
| P7 | **One page → one primary job → one core message.** | TLPC-V (refuses "47 things it must say") | strategist, architect, verifier | Always | Multi-SKU catalogues: one job per page, not one product |
| P8 | **Every section must have a job** (or it is cut). | TLPC-O (house sequence) + SYS (explicit section-jobs artifact) | architect, critic | Always | — |
| P9 | **Every major claim has evidence.** | SYS (TLPC's own public claims were unaudited/contradictory) | all | Always | — |
| P10 | **Quantify proof where legitimate.** | TLPC-V ("no testimonials until there's a number next to them") | copywriter | When real numbers exist | Never invent numbers; qualitative proof labelled as such beats a fake figure |
| P11 | **Handle objections explicitly** (ranked inventory, each discharged somewhere). | TLPC-O (4/4 pages) | strategist, architect, copywriter | Always | — |
| P12 | **Self-disqualification / wrong-fit filtering** where it improves trust and customer quality. | TLPC-O (2/4 pages, the two highest-attribution ones) | positioning, architect | Wrong-fit buyers drive returns/refunds/churn, or trust is low | Impulse/low-risk purchases with no wrong-fit harm — may add friction; justify either way |
| P13 | **Specific risk reversal** (number + terms). | TLPC-V (offer) / TLPC-O (client pages) | positioning, copywriter | When the business actually offers it | Never invent a guarantee; if none exists, recommend one to the user as a business decision |
| P14 | **Design mobile-first.** | TLPC-V | designer, builder, verifier | Always (verify against device split) | Desktop-dominant B2B traffic: still mobile-correct, desktop-optimised |
| P15 | **Real QA before shipping** (independent, real rendering). | TLPC-V (dedicated QA role) + SYS (automated checks, independent critic) | cro-critic, verifier | Always | — |
| P16 | **Baseline before measuring improvement.** | TLPC-I (implied by guarantee) + SYS (made mandatory) | platform-analysis, strategist | Always | No data → exact "cannot currently be validated" wording |
| P17 | **No CVR win if customer quality deteriorates** (PROMOTE/KILL rule written before launch). | TLPC-V as stated "wrong win" kill; SYS (numeric thresholds, pre-registration) | strategist, verifier | Whenever an experiment is proposed | Thresholds UNDEFINED until user data supports them |
| P18 | **Do not copy page structures blindly.** The observed TLPC sequence (symptom → commercial choice → legitimacy → self-qualification → mechanism → substantiation → social proof → differentiation → objection clearance → compliance) is a reference only. | SYS (dossier: attribution uncertain; discount-led client pages contradict TLPC philosophy) | architect | Always | — |

## System improvements over the TLPC public methodology (SYS)

The dossier found no documented experimentation system, significance thresholds, sample-size method or audited results. This system adds:
1. Mandatory baseline recording and an explicit TARGET vs VALIDATED RESULT distinction.
2. Sample-size / duration estimate (Lehr approximation) and honest "cannot currently be validated" wording.
3. Pre-registered PROMOTE/KILL guardrails with numbers, enforced at verification.
4. An evidence registry with grades and a validator that blocks untraceable claims.
5. Independent critic + verifier with an engine that recomputes the verdict rather than trusting it.
6. A machine-enforced user approval gate and a hard iteration cap.
7. Breadth research (reviews, forums, competitor reviews) in addition to depth interviews — the dossier notes TLPC names neither.
