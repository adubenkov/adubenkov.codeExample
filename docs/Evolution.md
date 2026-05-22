# Evolution: 2013 → 2026

How my iOS engineering approach changed across product and freelance work.

## Timeline

| Period | Context | Architecture | Notable skills |
|---|---|---|---|
| 2013–14 | Outsourcing studio | UI-first client apps | UIKit, App Store shipping |
| 2015–16 | Outsourcing studio | Obj-C → Swift transition | Foundation, publishing |
| 2016–20 | Outsourcing studio (audio product) | Modular MVP | AudioKit, DI via `Has*`, Realm, StoreKit |
| 2020–22 | Freelance (international clients) | Product ownership, SwiftUI | End-to-end delivery, backend for mobile |
| 2022–26 | Consumer app (remote product team) | Protocol services, async/await | Subscriptions, deep links, feature flags, extensions |

## Three phases of growth

### 1. Modular MVP (2016–2019)

[`legacy/audio-production-app/`](../legacy/audio-production-app/) — Presenter + State + protocol-composed services. Completion handlers, singleton containers, URL deep links via `NotificationCenter`.

**Lesson learned:** modularity early helps, but singletons and untested routing become expensive at scale.

### 2. Product ownership (2020–2022)

Freelance contracts with international clients. Owned features end-to-end — API integration, UI, release. SwiftUI on smaller products; UIKit on larger ones.

**Lesson learned:** service boundaries matter more than folder structure when multiple contributors ship in parallel.

### 3. Production platform (2022–2026)

Consumer subscription app (iPhone + iPad, Widget / NotificationService / Intent extensions). Excerpts in this repo are anonymized.

Refactors and new work moved toward:

- **Protocol-first services** — vendor SDKs behind narrow interfaces
- **Pure domain state** — `TrialState`, routing enums, policy maps
- **async/await** — e.g. UserPolicy load (`examples/async-policy/`)
- **Exhaustive unit tests** — mocks with `mock...` naming (`docs/CodeStyle.md`)
- **Team standards** — code style guide, review conventions, ADRs

## Before / after snapshots

| Area | Before | After | Doc |
|---|---|---|---|
| Deep links | Singleton parser + NotificationCenter | Protocol contexts + auth gate + tests | [`docs/refactors/deeplink-2019-vs-2025.md`](refactors/deeplink-2019-vs-2025.md) |
| User policies | Legacy controller | `UserPolicyService` + async configure | [`docs/decisions/002-user-policy-protocol-extraction.md`](decisions/002-user-policy-protocol-extraction.md) |
| Trial routing | Scattered conditionals | `TrialState` enum + tests | [`examples/subscription-state/`](../examples/subscription-state/) |

## Audio → consumer apps (same problems, different domain)

Background in audio (real-time state, session interruptions, queue-heavy work) maps directly to paginated feeds, subscription flows, and notification-driven routing. Different domain, similar constraints: **state must survive interruptions, and side effects belong at the edges**.

## What this repo includes

- **Sanitized excerpts** — patterns and tests, not proprietary product logic
- **Legacy audio MVP** — proof of deep audio domain experience
- **Docs** — decisions, feature briefs, interview walkthrough

Full production apps, API keys, and vendor configurations are intentionally excluded.
