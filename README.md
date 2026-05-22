# adubenkov.codeExample

Curated Swift iOS samples for hiring — production patterns, tests, and engineering standards.  
**Extension of my CV:** [LinkedIn](https://www.linkedin.com/in/adubenkov/) · [GitHub](https://github.com/adubenkov/adubenkov.codeExample)

## About

iOS developer, 10+ years (product + freelance). Since 2022 — consumer subscription app (iPhone + iPad, deep links, feature flags, app extensions). Previously ~4,000 hours on a production AudioKit app. Contributor to a team code style guide.

This repository contains **anonymized, sanitized excerpts** — architecture, domain logic, and tests. No employer or product names, API keys, or proprietary business logic.

Also experienced with: BLE integrations, SwiftUI freelance, Widget / NotificationService extensions, subscription and attribution SDKs (boundaries only here).

---

## Start here

| Audience | Path | Time |
|---|---|---|
| Recruiter / HM | This README → [`docs/Evolution.md`](docs/Evolution.md) → [`docs/CodeStyle.md`](docs/CodeStyle.md) (first sections) | ~5 min |
| iOS peer | [`examples/deep-link/`](examples/deep-link/) tests → [`examples/async-policy/`](examples/async-policy/) → [`docs/decisions/`](docs/decisions/) | ~15 min |
| Architect | All ADRs → [`docs/features/`](docs/features/) → [`docs/InterviewWalkthrough.md`](docs/InterviewWalkthrough.md) | ~30 min |

---

## Skill map (CV → repo)

| CV skill / work | Where to look |
|---|---|
| Code style guide author | [`docs/CodeStyle.md`](docs/CodeStyle.md) |
| Deep linking & attribution | [`examples/deep-link/`](examples/deep-link/) · [ADR 001](docs/decisions/001-deeplink-attribution-boundary.md) |
| Subscriptions / experiments | [`examples/subscription-state/`](examples/subscription-state/) · [ADR 003](docs/decisions/003-trial-state-pure-enum.md) |
| UserPolicy async refactor | [`examples/async-policy/`](examples/async-policy/) · [ADR 002](docs/decisions/002-user-policy-protocol-extraction.md) |
| Post-Trial Survey (E2E) | [`examples/survey-flow/`](examples/survey-flow/) · [feature brief](docs/features/post-trial-survey.md) |
| Server-Controlled Feed Inserts | [feature brief](docs/features/server-controlled-feed-inserts.md) + async-policy |
| Alternative sources carousel | [feature brief](docs/features/alternative-media.md) |
| AudioKit / Core Audio (~4,000h) | [`legacy/audio-production-app/`](legacy/audio-production-app/) |
| Architecture evolution 2013→2026 | [`docs/Evolution.md`](docs/Evolution.md) |
| Deep link before/after | [`docs/refactors/deeplink-2019-vs-2025.md`](docs/refactors/deeplink-2019-vs-2025.md) |

---

## Examples (Swift PM + tests)

```bash
# Run all packages
./scripts/test-all.sh

# Or individually
cd examples/deep-link && swift test
cd examples/subscription-state && swift test
cd examples/async-policy && swift test
cd examples/survey-flow && swift test
```

| Package | Demonstrates |
|---|---|
| [`deep-link`](examples/deep-link/) | Protocol contexts, attribution boundary, auth gating, 20+ tests |
| [`subscription-state`](examples/subscription-state/) | TrialState decision tree, remote config, paywall routing |
| [`async-policy`](examples/async-policy/) | async/await configure, policy map, mock API tests |
| [`survey-flow`](examples/survey-flow/) | Branching survey, async service, flow controller |

---

## Documentation

| Doc | Purpose |
|---|---|
| [`docs/CodeStyle.md`](docs/CodeStyle.md) | Review conventions (Good/Bad) |
| [`docs/Evolution.md`](docs/Evolution.md) | Career timeline, architecture growth |
| [`docs/decisions/`](docs/decisions/) | Mini-ADRs (3) |
| [`docs/features/`](docs/features/) | E2E feature briefs (sanitized) |
| [`docs/InterviewWalkthrough.md`](docs/InterviewWalkthrough.md) | Technical discussion guide |
| [`docs/refactors/`](docs/refactors/) | Before/after comparisons |

---

## Legacy

[`legacy/audio-production-app/`](legacy/audio-production-app/) — 2016–2019 modular audio MVP (Presenter/State/DI, StoreKit, Realm).  
Compare deep links with [`docs/refactors/deeplink-2019-vs-2025.md`](docs/refactors/deeplink-2019-vs-2025.md).

---

## Intentionally not included

- Full production app sources
- Employer, product, or brand identifiers
- Vendor SDK configs and API keys
- Proprietary content logic
- UI storyboards as primary samples (legacy only, for context)

---

## Author

**Andrey Dubenkov** — iOS engineer · Remote (Omsk, GMT+6)  
[hrnthrnt@gmail.com](mailto:hrnthrnt@gmail.com) · [LinkedIn](https://www.linkedin.com/in/adubenkov/)

Русская версия: [`README.ru.md`](README.ru.md)
