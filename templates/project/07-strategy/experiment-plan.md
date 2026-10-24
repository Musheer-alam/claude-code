<!-- LPCRO:TEMPLATE -->
# 07 · Experiment & Measurement Plan

> Owner: conversion-strategist (experimentation skill). The 20% figure is an OPTIMISATION TARGET, never a promised or validated result.

## Baseline (copied from state; source + window)
| Metric | Baseline | Source |
|---|---|---|
| Primary CVR | | |
| AOV | | |
| Revenue per visitor | | |
| Return rate | | |
| Repeat rate | | |
| LTV | | |

## Target
- Relative target: ≥20% relative improvement in primary CVR. Example: baseline 2.0% → target 2.4% (NOT 22%).
- Validation feasibility: FEASIBLE / INSUFFICIENT_TRAFFIC / NO_BASELINE / TRAFFIC_UNKNOWN (from `lpcro.ps1 baseline`)
- Required statement if not feasible: "20% improvement cannot currently be validated because a reliable baseline is unavailable." / "20% improvement cannot currently be statistically validated with available traffic."

## Design
- Method: A/B split (preferred) / sequential before-after with confounds listed / holdout
- Tool: (named, or NOT AVAILABLE)
- Split, sample size per arm, minimum duration (full weeks; cover ≥1 business cycle), stopping rule (no peeking-based early stops)
- Confounds to control/log: ad spend changes, creative refresh, promos, seasonality, stock-outs

## Metrics
- Primary: CVR (single, pre-registered)
- Secondary: AOV, revenue per visitor
- Quality guardrails: return/refund/RTO rate, repeat rate, LTV (30/60/90-day reads)

## LTV / WRONG-WIN GUARDRAIL (recorded BEFORE the experiment)
PROMOTE only if ALL:
- CVR increases (meets the pre-registered decision rule)
- AND AOV does not decline more than ___%
- AND return/refund rate does not rise more than ___ pp
- AND early LTV proxy (e.g. 30-day repeat) does not fall more than ___%

KILL if:
- CVR increases BUT return rate rises more than ___ pp
- OR LTV / repeat proxy falls more than ___%
- OR AOV falls more than ___%

HOLD (extend to next read) if mixed.

LTV GUARDRAIL STATUS: UNDEFINED until every blank above has a number agreed with the user (then `lpcro.ps1 guardrail -Status DEFINED -Summary "..."`).

## Read schedule
- Week 1: health check only (no decisions)
- Week 2+: decision read on CVR + returns
- Day 30/60/90: LTV / repeat reads
## Instrumentation required (events, UTM, data layer)
