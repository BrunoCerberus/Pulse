# SEVERITY_RUBRIC.md — Pulse iOS

> Used by the security-discovery and verification passes (and human triage) to score
> findings **consistently and against real reachability**, not in the abstract. Score
> every finding on the five dimensions below *before* assigning a severity. Ground the
> scoring in `THREAT_MODEL.md` — that is the antidote to LLM severity inflation.

## The five dimensions

| Dimension | Question |
|---|---|
| **Reachability** | Can an attacker reach this sink from a real entry point in `THREAT_MODEL.md` §2 (article JSON, push payload, share URL, `pulse://`)? Or is it dead/internal code? |
| **Attacker control** | Does genuinely untrusted input reach the sink, or is it sanitized/constrained upstream (HTML-strip, allowlist, type, length cap)? |
| **Preconditions** | Non-default settings, feature flags, specific app state, or timing windows required? |
| **Authentication** | Unauthenticated · authenticated user · admin/owner only? (Most of Pulse sits behind Firebase auth.) |
| **Blast radius** | One field on screen · the local user's data · all of one user's devices (CloudKit private zone) · all users? |

## Scoring guidance

| Severity | Rule of thumb |
|---|---|
| **Critical / High** | 0 preconditions **and** unauthenticated reach **and** attacker-controlled input to a damaging sink. |
| **Medium** | 1–2 preconditions, **or** requires an authenticated session, **or** attacker control is partial. |
| **Low** | 3+ preconditions, **or** local-only / requires physical device access, **or** input is already strongly constrained upstream. |
| **Info / Won't-fix** | Not reachable from a real entry point, behind a trusted boundary (per §2), or impact is purely cosmetic. |

## Pulse-specific calibration

- **Default ceiling is Medium.** Nearly every flow sits behind Firebase auth and a
  **private** CloudKit zone, and there is **no server code in this repo** — so the
  "unauthenticated + remote + platform-wide" combination that earns Critical on a
  backend rarely applies here. A finding claiming Critical must justify how it clears
  the auth + private-data preconditions.
- **On-device LLM findings are bounded.** The Gemma model has no tool access and no
  network; its output is a user-facing summary/tags. Prompt-injection findings there
  are typically **Low–Medium** (manipulated output), not High, unless they reach a
  privileged sink.
- **Trusted inputs are not vulnerabilities.** Findings whose "attacker" is the
  authenticated user's own config, the Keychain, or Remote Config are Info/Won't-fix
  unless a real cross-trust-boundary path is shown.

## Required output per finding

```
title:        <one line>
file:line:    <path:line>
class:        <vuln class from THREAT_MODEL.md §3, or "other">
reachability / attacker-control / preconditions / auth / blast-radius:  <one line each>
severity:     Critical | High | Medium | Low | Info
status:       proven (PoC) | unproven
poc:          <failing Swift Testing case or repro steps, or "none — flagged unproven">
```

A finding with no PoC is **not** automatically a false positive — report it as
`unproven` so recall isn't lost, but it must not be ranked above a proven finding of
the same nominal severity.
