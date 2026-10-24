---
name: ux-ui
description: LP-CRO conversion UX/UI design method — mobile-first layouts where visual hierarchy encodes message priority, proof before the first scroll, CTA system, component consistency, credibility ("2027 test"), accessibility and performance budgets.
---

# Skill: UX/UI Design

## Purpose
Design that makes the strategy legible on a phone. Hierarchy encodes priority: the most dominant element supports the highest-priority message, not the prettiest asset. (P14; TLPC VERIFIED trust factor: "will it still exist in 2027?")

## Inputs
Strategy hierarchy, page map, section jobs, wireframe, final copy, brand assets, existing page snapshots, audit preserve list.

## Process
1. **Brand inputs**: tokens from guidelines/assets; else derived from the live page (state it).
2. **Tokens**: colour (ink, surface, accent reserved for primary CTA, proof colour), type scale (mobile body ≥16px, line-height 1.5; display sizes clamp mobile→desktop), spacing on a 4/8 scale, radius, shadows (sparingly).
3. **Priority → weight map**: rank elements per screen; assign size/contrast/position accordingly.
4. **First viewport (mobile ~360×740)**: headline, sub, primary CTA, ≥1 proof element (rating with count, credential, volume), offer cue; no carousel-dependent hero; product image only if it aids recognition.
5. **Sections**: mobile layout first (single column, thumb-reachable CTAs, accordions for long FAQ), then desktop delta (2-col where comparison/scan helps).
6. **CTA system**: one primary style used only for the primary action; secondary style for the soft conversion; sticky mobile CTA after the hero scrolls away (if it doesn't obscure content); states incl. focus-visible and loading.
7. **Proof/trust**: proof adjacent to the claim it supports; quantified proof styled as data (numbers prominent, source small but present); certifications as a calm row, not a badge wall.
8. **Components**: cards, badges, proof blocks, testimonial cards, FAQ items, comparison rows — shared padding, edges, baselines.
9. **Credibility**: restraint, consistent alignment, real imagery, no gimmicks that age (the 2027 test).
10. **Performance budget**: LCP < 2.0s on mobile 4G target; hero image ≤ 120KB (AVIF/WebP), font subsets, `font-display: swap`, no layout shift from late assets.
11. **Accessibility**: WCAG AA contrast; ≥44px targets; visible focus; reduced motion; meaningful order.

## Decision rules
- Decorative elements never outrank the headline or CTA.
- Every interaction must earn its friction (quiz/accordion/carousel justified by a job).
- Do not change copy; request cuts if needed.

## Outputs
`10-design/design-system.md`, `design-spec.md`, `component-spec.md`.

## Failure conditions
Copy/hierarchy mismatch → PARTIAL with requested copy cuts.

## Quality checks
- [ ] Priority map present; first viewport compliant
- [ ] Components defined and reused
- [ ] Contrast/targets/motion specified
- [ ] Performance budget stated
