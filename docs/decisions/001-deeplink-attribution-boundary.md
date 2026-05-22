# ADR 001: Deep link attribution boundary

**Status:** Accepted  
**Context:** Consumer app routing (2024–2026, anonymized)

## Decision

Deep link routing depends on an `AttributionService` protocol. The manager exposes `shouldResolve(context:)` and `resolve(context:)` — never vendor-specific method names in the manager API.

Vendor host names live in `AttributionConstants` on the implementation side.

## Why

- Deferred / tracking links must be resolved before URL parsing.
- Attribution SDK may change; routing rules should not.
- Unit tests mock `AttributionService` without linking vendor frameworks.

## Consequences

- **Positive:** testable routing, clear seam for SDK swaps, review-friendly API surface.
- **Negative:** one indirection layer; resolved URL arrives asynchronously via subscription.

## Code

- [`examples/deep-link/Sources/DeepLinkExample/DeepLink/AppDeepLinkManager.swift`](../../examples/deep-link/Sources/DeepLinkExample/DeepLink/AppDeepLinkManager.swift)
- [`examples/deep-link/Tests/DeepLinkExampleTests/AppDeepLinkManagerTests.swift`](../../examples/deep-link/Tests/DeepLinkExampleTests/AppDeepLinkManagerTests.swift)

## Alternatives considered

| Alternative | Rejected because |
|---|---|
| Parse all URLs synchronously in app delegate | Breaks deferred install / tracking links |
| Import vendor SDK in manager | Untestable, leaks vendor into routing layer |
| NotificationCenter bridge | Same problems as 2019 legacy pattern |
