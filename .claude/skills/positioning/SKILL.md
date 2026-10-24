---
name: positioning
description: LP-CRO audience & offer positioning method — decide which buyer the page recruits, core promise, offer framing, discount rules, specific risk reversal, allowed/forbidden persuasion devices and LTV guardrails, using LTV as a strategic guardrail rather than optimising CVR alone.
---

# Skill: Positioning

## Purpose
"The page chooses your customer" (TLPC VERIFIED stated position; whether practised: UNKNOWN). Decide deliberately which buyer to recruit and protect customer quality. (P5, P6, P12, P13, P17.)

## Inputs
Discovery, customer intelligence (segments, objections, language), platform data (AOV, LTV, returns, discount use), competitive intelligence (category discount norms, white space).

## Process
1. **Recruited today**: what the hero, offer and ads promise (discount-led? outcome-led? brand-led?), who reviews come from, return/refund signals.
2. **Should recruit**: segment with best evidence of value (LTV/repeat/low returns/high margin) *and* reachable by the traffic the page actually gets.
3. **Wrong-win analysis**: list plausible CVR levers (bigger discount above the fold, urgency timers, over-promising outcomes, removing fit information) and for each, the customer-quality risk mechanism (discount buyers churn; over-promise → returns; no fit info → wrong-fit buyers).
4. **Positioning statement** (template in artifact), **core promise** (provable), **offer framing** (anchor, ladder, subscription logic tied to efficacy/usage evidence, not merchandising for its own sake).
5. **Discount rules**: where a discount may appear (e.g. pack-ladder savings below the fold) and where it may not (hero headline) — justified by LTV evidence or, absent data, by stated risk.
6. **Risk reversal**: only real terms (days, what is refunded, conditions) with evidence; if none exists, recommend one to the user as a business decision — never write one into copy.
7. **Persuasion devices**: allowed (with why) / forbidden (fake scarcity, unverifiable claims, countdowns that reset, before/after imagery in regulated categories, pressure tactics that raise returns).
8. **LTV guardrail proposal**: PROMOTE and KILL thresholds (AOV floor, return-rate ceiling in pp, repeat/LTV floor) with the baseline numbers they are anchored to. If inputs are missing: `UNDEFINED` + the exact data request.

## Decision rules
- If LTV by segment is unknown, prefer the positioning that does not depend on discount-led acquisition, and mark the choice INFERRED.
- Self-disqualification (wrong-fit filter) is recommended when wrong-fit purchases drive returns/refunds/churn or when trust is low; otherwise justify omission.
- Thresholds suggested without client data are labelled PROPOSED and require user confirmation before `guardrail -Status DEFINED`.

## Outputs
`06-positioning/positioning.md`; evidence E-500–E-599; DECISIONs (audience choice, discount policy).

## Failure conditions
Economics unknown → guardrail UNDEFINED; confidence lowered; request data.

## Quality checks
- [ ] Today vs should-recruit both evidenced
- [ ] Wrong-win risks listed with mechanisms
- [ ] Risk reversal real or absent (never invented)
- [ ] Guardrail numeric or UNDEFINED with data request
