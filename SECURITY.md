# Security Policy

## Supported Versions

Pulse ships as a single, continuously updated iOS app. Only the latest version available on the App Store (and the current `master` branch) receives security fixes.

| Version | Supported |
| ------- | --------- |
| Latest App Store release | ✅ |
| Older releases | ❌ |

## Reporting a Vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities.

Instead, report privately using one of these channels:

- **GitHub Private Vulnerability Reporting**: open a report via the [Security tab](https://github.com/BrunoCerberus/Pulse/security/advisories/new) ("Report a vulnerability").
- **Email**: bruno.guitarpro@gmail.com

Please include:

- A description of the vulnerability and its potential impact
- Steps to reproduce (proof-of-concept code or requests, if applicable)
- Affected app version / commit hash

### What to expect

- Acknowledgement within **5 business days**.
- An initial assessment and, where possible, an estimated timeline for a fix within **10 business days**.
- Credit in the release notes/advisory if you'd like it, once the fix ships.

We ask that you give us a reasonable time to investigate and remediate an issue before any public disclosure.

## Scope

This policy covers the Pulse iOS app and its companion `pulse-backend` service. Third-party dependencies should be reported to their respective maintainers, though we appreciate a heads-up so we can track exposure.
