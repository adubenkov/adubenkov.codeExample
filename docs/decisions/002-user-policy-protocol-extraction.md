# ADR 002: UserPolicy protocol extraction

**Status:** Accepted  
**Context:** Consumer app refactor (2025, anonymized)

## Decision

Replace a legacy view-controller–coupled policy loader with:

- `UserPolicyService` protocol (`configure() async throws`, `isEnabled`, `limitFor`, `isUnlimited`)
- `AppUserPolicyService` implementation mapping API DTOs → typed `[UserPolicyKey: UserPolicy]`
- Unit tests with `MockPolicyAPIService`

## Before

Policy flags were loaded and queried through legacy UI-layer code. Hard to test, hard to call from ViewModels and content services consistently.

## After

Async configuration on startup or session refresh. Synchronous read accessors after configure — safe for UI binding and feed gating checks.

Policy value types (`binary`, `limit`, `both`) encoded once in the mapper; callers use semantic methods.

## Why

- Multiple features gate on the same policy keys (feed limits, premium features, experiments).
- async/await fits one-shot network load without callback pyramids.
- Fail-fast on configure errors preserves existing error handling; no silent defaults for missing keys (returns `false` / `nil`).

## Consequences

- **Positive:** test coverage for edge cases (invalid API rows, nil policies, unlimited `-1` limits).
- **Negative:** callers must ensure `configure()` completed before trusting reads.

## Code

- [`examples/async-policy/`](../../examples/async-policy/)

## Related

- [`docs/refactors/deeplink-2019-vs-2025.md`](../refactors/deeplink-2019-vs-2025.md) — same “extract protocol + tests” pattern
