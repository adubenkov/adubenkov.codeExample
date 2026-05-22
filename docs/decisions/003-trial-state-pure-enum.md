# ADR 003: TrialState as pure enum

**Status:** Accepted  
**Context:** Subscription onboarding (2025, anonymized)

## Decision

Model trial onboarding outcomes as a pure `TrialState` enum resolved from many inputs (subscription eligibility, remote config cohort, promotional offers, feature-flag payloads, paywall campaign strings).

Return `nil` when no trial UI should appear — not a sentinel “empty” case.

## Why

- Subscription onboarding has combinatorial rules; nested `if` chains in ViewModels were hard to review and untestable.
- Enum cases (`introductoryOffer`, `promotionalOffer`, `paywallCampaign`) map 1:1 to UI entry points.
- Exhaustive tests document business rules better than comments.

## Consequences

- **Positive:** 30+ scenarios testable without StoreKit or paywall SDK; refactors are diff-friendly.
- **Negative:** initializer takes many parameters — acceptable because call site is a single service/factory.

## Alternatives considered

| Alternative | Rejected because |
|---|---|
| Bool flags on ViewModel (`showTrial`, `showPromo`, …) | Combinatorial bugs, unclear priority |
| Class with mutable state | Hidden side effects, harder tests |
| Paywall SDK as source of truth | Vendor lock-in at domain layer |

## Code

- [`examples/subscription-state/Sources/SubscriptionStateExample/TrialState.swift`](../../examples/subscription-state/Sources/SubscriptionStateExample/TrialState.swift)
- [`examples/subscription-state/Tests/SubscriptionStateExampleTests/TrialStateTests.swift`](../../examples/subscription-state/Tests/SubscriptionStateExampleTests/TrialStateTests.swift)
