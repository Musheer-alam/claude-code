---
name: discovery
description: LP-CRO discovery & qualification method — research a business and its landing page from a URL, decide whether it qualifies for optimisation, and generate only decision-changing questions. Used by the discovery agent.
---

# Skill: Discovery & Qualification

## Purpose
Establish the business facts every later decision depends on, and decide whether optimisation is worthwhile and measurable. (Principle P1, TLPC VERIFIED: qualification before execution.)

## Inputs
Landing URL (required); business URL, product, conversion goal, traffic, CVR, AOV, access, assets (optional) from `00-intake/intake.md`.

## Process
1. **Capture the page**: fetch (WebFetch); if JS-rendered/blocked, load in the built-in browser at 375×812 and 1440×900; save screenshots + DOM text to `05-audit/snapshots/<date>-<viewport>.*`. Record hero, CTAs, forms, prices, offer terms, scripts/pixels present (Meta Pixel, GA4, Clarity, Hotjar, Shopify, Klaviyo — these indicate data that may exist).
2. **Crawl the business surface** (max ~10 pages): home, product/pricing, shipping/returns/refund policy, FAQ, about, contact, reviews page. Note business model (D2C / lead-gen / SaaS / marketplace / service), price points, packs/bundles/subscription, guarantees, payment options (COD, BNPL).
3. **Public footprint**: review platforms and marketplaces (ratings + counts as shown, with date), ad libraries (are there active ads? what do they promise?), press, social proof claims on site (record as CLAIMS, grade OBSERVED, not VERIFIED).
4. **Synthesize**: primary business objective; primary conversion (one); current page job; funnel steps; growth blocker (user-stated vs observed); page importance; constraints (regulated claims, brand, platform, legal).
5. **Unknowns triage** — for each unknown ask: *does the answer change audience, offer, primary conversion, archetype or measurement?* If yes and not discoverable → CRITICAL question. If it only sharpens confidence → NICE-TO-HAVE (record as missing, don't ask).
6. **Qualify**.

## Decision rules
- QUALIFIED: commercial page with a clear conversion, reachable, enough information to proceed.
- QUALIFIED_WITH_CAVEATS: proceed but measurement is limited (no baseline, low traffic, no data access) or key inputs missing — caveats listed.
- NOT_QUALIFIED: no commercial intent / no conversion path / page is not the business's / restricted category / the user's goal cannot be served by a landing page change (e.g. product out of stock, broken checkout outside page scope).
- Traffic sufficiency: if CVR and monthly sessions are known, a 50/50 test needs ≈ 16·p(1−p)/(0.2p)² sessions per arm; > 8 weeks ⇒ "cannot be statistically validated with available traffic" (still can qualify with caveats).
- Ask at most 5 CRITICAL questions, one message, each naming the decision it unlocks. Typical CRITICAL: primary conversion when ambiguous; which audience/offer when the page serves several; whether discounts are allowed; access to analytics when the user said it exists.

## Outputs
`01-discovery/discovery.md`; evidence E-001–E-099; snapshots.

## Failure conditions
Unreachable URL (all methods) → BLOCKED/URL_INACCESSIBLE with methods tried and request for HTML/screenshots. Ambiguous page (several products, several CTAs) → CRITICAL question on primary job.

## Quality checks
- [ ] Every fact tagged or marked UNKNOWN/NOT AVAILABLE/NOT VERIFIED
- [ ] One primary conversion named (or CRITICAL question)
- [ ] Qualification + data-sufficiency statement
- [ ] Questions are few, critical, decision-linked
- [ ] Site-displayed claims (e.g. "10,000+ happy customers") recorded as OBSERVED claims, not facts
