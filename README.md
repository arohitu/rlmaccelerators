<!-- ---------------------------------------------------------------------
README.md for Revenue-Cloud-Accelerators
------------------------------------------------------------------------ -->

<!-- Badges (swap the dummy URLs) -->
![Build](https://img.shields.io/github/actions/workflow/status/your-org/repo/ci.yml?label=CI)
![Latest Release](https://img.shields.io/github/v/release/your-org/repo)
![License](https://img.shields.io/github/license/your-org/repo)

# Revenue‑Cloud Accelerators

Collection of opinionated, field‑tested Salesforce packages that speed up Revenue Cloud projects and pre‑sales demos.  
Everything here has shipped in the real world; everything here still evolves.

> **Straight talk:** These accelerators save weeks, but they’re not silver bullets.  
> Validate every line against your client’s org and compliance rules before pushing to production.

---

## Table of Contents
1. [What’s Inside](#whats-inside)
2. [Quick Start](#quick-start)
3. [Package Index](#package-index)
4. [Usage Examples](#usage-examples)
5. [Contributing](#contributing)
7. [Support & Maintenance](#support--maintenance)
8. [License](#license)

---

## What’s Inside

| Folder | Accelerator |
| ------ | ----------- |
| `rca-approval` | **Advanced Approval Starter** |

---

## Quick Start

1. **Pick your package** – browse the [Package Index](#package-index) below.
2. **Click the install link** – log in with admin credentials to the target sandbox, scratch org, or production org.
3. **Approve security prompts** – Salesforce may ask to grant access to external services or Apex classes; review and proceed.
4. **Post‑install** – assign the provided Permission Set(s) and run any optional setup Flow listed in the docs.

_That’s it. No CLI. No scratch‑org gymnastics._

> **Dependencies:** If a package relies on CPQ, B2B Commerce, or another managed package, ensure it’s installed **first**. The install link will fail otherwise.

---

## Package Index

| Accelerator | Version | Install Link | Docs |
| ----------- | ------- | ------------ | ---- |
| RCA Approvals  | ![version](https://img.shields.io/static/v1?label=latest&message=1.4.0&color=informational) | [Install](https://login.salesforce.com/packaging/installPackage.apexp?p0=04td200000050fJAAQ) | [/docs/usage-metrics](rca-approval/main/default/AdvApproval.md) |

---

## Contributing

* **Fork → branch → pull request.** We keep the commit history clean; squash merges only.  
* Follow the style guides in `/CODEOWNERS` and `/eslint-config`.  
* Open an issue *before* you start major work—no drive‑by mega PRs.  
* By contributing, you agree to the [Contributor License Agreement](CLA.md).

---

## Support & Maintenance

* Open a GitHub Issue for bugs.  
* For paid support or bespoke adaptations, email **revcloud@your-domain.com**.  
* Major releases every six weeks, security patches ad‑hoc.

---

## License

Apache 2.0—permissive for commercial use.  
If that doesn’t fit your legal department, fork and roll your own.

---

### Acknowledgements

Built by architects who still write code, not slide decks.  
Leverages lessons from >50 Revenue Cloud deployments since 2016.
