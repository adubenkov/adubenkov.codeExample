# adubenkov.codeExample

Curated Swift iOS code samples for hiring: architecture patterns, testable domain logic, and team code-review standards.

## What is here

| Section | What it shows |
|---|---|
| [`docs/CodeStyle.md`](docs/CodeStyle.md) | Code review conventions with Good/Bad examples |
| [`examples/deep-link/`](examples/deep-link/) | Protocol-driven deep link routing, attribution boundary, unit tests |
| [`examples/subscription-state/`](examples/subscription-state/) | Trial-state decision logic with remote config and experiments |
| [`legacy/music-mvp-2019/`](legacy/music-mvp-2019/) | Early modular MVP: Presenter/State/DI, StoreKit, Realm |

## How to read this repo

Start with the two `examples/` packages — they reflect recent production patterns (2024–2026). The legacy MVP shows earlier architecture from 2018–2019.

Each example is a standalone Swift Package with tests:

```bash
cd examples/deep-link && swift test
cd examples/subscription-state && swift test
```

## Patterns demonstrated

- **Dependency injection** via protocol composition (`Has*` services in legacy MVP)
- **Module boundaries** — Presenter, ViewModel, State (legacy); service layer with protocols (examples)
- **Vendor isolation** — attribution and paywall vendors hidden behind protocols/constants
- **Testable domain logic** — routing and subscription state resolved as pure functions with exhaustive tests
- **Review-driven style** — explicit `return`, mock naming, test layout rules

## Intentionally not included

- Full app sources, API keys, product identifiers from production
- UI storyboards as primary samples (legacy code includes them for historical context only)
- Third-party SDK dependencies (RevenueCat, AppsFlyer, etc.) — only abstractions and sanitized logic

## Author

Andrey Dubenkov — iOS engineer.
