# Security Policy

## Supported Versions

Pulse ships as a single, continuously updated iOS app. Only the latest version available on the App Store (and the current `master` branch) receives security fixes.

| Version | Supported |
| ------- | --------- |
| Latest App Store release | ✅ |
| Older releases | ❌ |

## Reporting a Vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities.

Report privately through [GitHub Private Vulnerability Reporting](https://github.com/BrunoCerberus/Pulse/security/advisories/new) — the "Report a vulnerability" button on the [Security tab](https://github.com/BrunoCerberus/Pulse/security). This is the only supported reporting channel; it is private to the maintainers and lets us coordinate a fix and an advisory in one place.

Please include:

- A description of the vulnerability and its potential impact
- Steps to reproduce (proof-of-concept code, payload, or deeplink, if applicable)
- The entry point involved — see the untrusted inputs in [`THREAT_MODEL.md`](THREAT_MODEL.md) §2
- Affected app version / commit hash

### What to expect

- Acknowledgement within **5 business days**.
- An initial assessment and, where possible, an estimated timeline for a fix within **10 business days**.
- Credit in the advisory if you'd like it, once the fix ships.

We ask that you give us a reasonable time to investigate and remediate an issue before any public disclosure.

## Before You Report

This repository already documents its own security model, and reading it first will save you time:

- [`THREAT_MODEL.md`](THREAT_MODEL.md) — trust boundaries, untrusted inputs, and the vulnerability classes we actively track, with the defenses currently in place for each.
- [`SEVERITY_RUBRIC.md`](SEVERITY_RUBRIC.md) — how we score findings (reachability, attacker control, preconditions, authentication, blast radius).

Note that severity here is scored against **real reachability**, not in the abstract. Most flows sit behind Firebase authentication and a private CloudKit zone, so the rubric's default ceiling is **Medium**.

## Scope

**In scope** — the Pulse iOS app, its extensions (Share, Widget/Live Activity), and the CI workflows in this repository.

**Out of scope:**

- **The backend.** The self-hosted Supabase Go RSS worker lives in the separate `pulse-backend` repository and is threat-modeled there. There is no server code in this repository, so server-side issues (SQLi, RCE, RLS) should be reported against that repo instead.
- **Third-party dependencies.** Report these to their respective maintainers. A heads-up is still welcome so we can track our exposure — but a CVE in a dependency with no reachable call path from an entry point in `THREAT_MODEL.md` §2 is tracked, not fixed as an incident.
- **Findings not reachable from a real entry point**, or behind a component listed as trusted in `THREAT_MODEL.md` §2.
- **The reviewer-only anonymous sign-in path**, which is intentionally hidden rather than hardened.
- Known, documented residuals already recorded in `THREAT_MODEL.md` §3 — most notably that plain-language instruction text in article fields is deliberately not censored (censoring it would break legitimate news coverage). Reports of *new, unfixed variants* of a documented class are very much in scope.
