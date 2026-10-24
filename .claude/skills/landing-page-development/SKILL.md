---
name: landing-page-development
description: LP-CRO landing page build method — inspect the existing project (framework, routing, components, styling, analytics, deployment) before changing anything, then implement the approved copy and design as semantic, accessible, fast, analytics-ready code (or a standalone page when no codebase exists), with self-checks in a real browser.
---

# Skill: Landing Page Development

## Purpose
Ship what was approved, exactly, as production-quality code — preserving existing functionality.

## Inputs
Final copy, design system/spec/components, wireframe, experiment plan (instrumentation), codebase path & deployment info.

## Process
1. **Inspect before modifying** (record in build notes): repo layout; framework (Next/Remix/Astro/Vue/Shopify theme/Webflow export/static); routing (where a new landing route/template goes); component library; styling (Tailwind/CSS modules/theme settings); analytics (GTM, GA4, Meta Pixel, Shopify pixels — keep them); deployment (Vercel/Netlify/Shopify CLI/manual). Run the project's own build/test commands to confirm a clean baseline.
2. **Plan**: map each approved section → component → file. Reuse existing components/tokens where they meet the design spec.
3. **Implement**:
   - Semantic HTML: one `h1` (the hero headline), sections with headings, `main`, `nav` only if justified, `footer`.
   - Copy exactly from `final-copy.md` with `[E-nnn]`/`[V-nnn]` tags removed.
   - Primary CTA → real destination (add-to-cart/checkout URL, form action, booking link). If unknown, a single documented config value (e.g. `data-cta-href` set at top of file) — never a dead `#`.
   - Tracking: `data-track="cta_primary|cta_secondary|faq_open|form_step_n"`, section-view events via IntersectionObserver pushing to `window.dataLayer` if present; UTM passthrough to CTA URLs.
   - Responsive mobile-first CSS; sticky CTA per spec; `prefers-reduced-motion`; focus-visible styles; labels for inputs; alt text from real asset descriptions (empty alt for decorative).
   - Performance: inline critical CSS for standalone builds; lazy-load below-fold images; width/height on images; preload hero image and primary font subset; no heavy libraries for simple interactions.
   - SEO where appropriate: title, meta description, canonical, Open Graph; `noindex` only if the page is ad-only and the user wants that.
   - Shopify themes: build as a section/template with settings; keep cart/variant logic native.
4. **Standalone mode** (no codebase): `11-build/index.html` self-contained + `11-build/assets/`; integration notes for the likely platform.
5. **Self-check** (not a score): `lpcro.ps1 validate`; open in the browser at 375 and 1440; zero console errors; click every link/CTA; keyboard-tab through; check the accessibility tree for headings/labels; screenshot to `11-build/screenshots/`.

## Decision rules
- Never change strategy, order or copy; deviations → report.
- Don't remove or break existing tracking, routes or pages.
- No placeholder text, lorem, fake reviews, fake counters, fake timers.

## Outputs
Code + `11-build/build-notes.md` (iteration log updated each time) + screenshots.

## Failure conditions
Build fails / stack can't express the spec → PARTIAL with exact error output and options.

## Quality checks
- [ ] Inspection recorded before changes
- [ ] Copy parity with final-copy.md
- [ ] Primary CTA functional; no broken links; no console errors
- [ ] Mobile verified in browser; a11y basics present
- [ ] Tracking hooks documented
