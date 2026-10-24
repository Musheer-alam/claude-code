---
name: platform-analysis
description: LP-CRO quantitative analysis method — establish the baseline first, then funnel, leakage, traffic, device, ad-to-page message match and behavioural signals from GA4/Shopify/Meta/Google Ads/Clarity/Hotjar/CRM/Search Console or exports. Read-only; never invents numbers.
---

# Skill: Platform & Data Analysis

## Purpose
Know what the data says before recommending anything. (P3, P16 — TLPC VERIFIED data stack; SYS: baseline made mandatory.)

## Inputs
Connected tools (detect, don't assume), user exports, discovery facts.

## Process
1. **Source inventory**: for each of GA4, Shopify, Meta Ads, Google Ads, Clarity/Hotjar, CRM/email, Search Console, attribution — connected? how? what window? If not, write what it would answer.
2. **Windows**: default last 28 complete days; also prior 28 and same period last year where possible (seasonality). State timezone.
3. **Baseline table** for the target page (and site for context): sessions, primary conversions, CVR = conversions ÷ sessions (state the definition: session-based vs user-based; purchase vs add-to-cart), AOV, revenue per visitor, return/refund/RTO rate, repeat rate, LTV (by acquisition source/discount use if possible).
4. **Funnel**: landing → engagement (scroll/CTA click) → add-to-cart/form start → checkout/form submit → purchase/lead. Drop-off % between steps.
5. **Traffic**: source/medium/campaign share and CVR; classify temperature (cold prospecting, warm retargeting, hot brand search/email).
6. **Device**: share and CVR by device; flag mobile gap (mobile CVR < 0.6× desktop is notable).
7. **Ads → page match**: top 5 ads by spend (or visible in ad library): promise, offer, visual → is it echoed in the page's first viewport? Score MATCH / PARTIAL / MISMATCH.
8. **Behaviour**: scroll depth to key sections, rage/dead clicks, form field abandonment, recordings reviewed (n, sampling method).
9. **Leakage inventory** sized in sessions or revenue where possible.
10. **High-value page** = importance (traffic/revenue share) × leakage.

## Decision rules
- Never mix relative and percentage-point changes; when reporting change, give both explicitly ("1.8% → 2.2%: +0.4 pp, +22% relative").
- GA4 vs Shopify disagreement → report both, likely cause (attribution, consent, bots), and which is used as baseline and why.
- Fewer than ~100 conversions in the window → baseline confidence LOW; widen window if stable.
- Baseline command for the orchestrator: `baseline -Cvr <pct> -Source "<tool, metric definition, page filter>" -Window "<dates>" -Sessions n -Conversions n -MonthlySessions n`, or `baseline -Unavailable -Reason "<why>"`.

## Outputs
`03-data/platform-analysis.md`; evidence E-200–E-299; baseline command line in handoff.

## Failure conditions
Nothing connected and no exports → NOT AVAILABLE everywhere; baseline UNAVAILABLE; minimal data request listed. Tracking broken (e.g. purchase events missing) → flag P0 measurement risk.

## Quality checks
- [ ] Baseline before recommendations
- [ ] Every figure: tool + window + filter + definition
- [ ] Derived numbers show arithmetic
- [ ] Missing sources and their impact listed
- [ ] Read-only: no platform changes made
