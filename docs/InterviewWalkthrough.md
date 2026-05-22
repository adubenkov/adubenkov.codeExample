# Interview walkthrough

Questions I would ask — or expect — when reviewing code from this repository.

Use this as a guided technical conversation, not a quiz with single answers.

---

## Deep link module

**Files:** [`examples/deep-link/`](../../examples/deep-link/)

1. What happens when a deferred link resolves to a URL the parser cannot map?
   - Expected: handled == true (resolution started), no pending link, no error — attribution succeeded but routing has nothing to show.

2. Why cache `pendingDeepLink` when the user is logged out instead of failing silently?
   - Expected: post-login continuation; error stream notifies UI to show login.

3. Why are vendor hosts in `AttributionConstants` rather than inside `AppDeepLinkManager`?
   - Expected: ADR 001 — vendor isolation, testability.

4. How would you add a new route type without regressions?
   - Expected: extend `DeepLinkType`, add parsing tests, add auth requirement test, add manager routing test.

5. Compare with [`legacy/audio-production-app/Services/DeepLinkManager.swift`](../../legacy/audio-production-app/Services/DeepLinkManager.swift). What breaks if we only add NotificationCenter posts?
   - Expected: no auth gate tests, no deferred links, global state.

---

## User policy (async)

**Files:** [`examples/async-policy/`](../../examples/async-policy/)

1. Why is `configure()` async but reads synchronous?
   - Expected: one network fetch; after success, hot in-memory map for UI.

2. What does `limit == -1` mean? Is the feature enabled?
   - Expected: unlimited; enabled depends on type (`limit` type always enabled; `both` checks `enabled` flag).

3. What is returned for an unknown policy key before configure?
   - Expected: `false` / `nil` — no fabricated defaults.

4. How do you test API failure without a live backend?
   - Expected: `MockPolicyAPIService` throws; test expects error propagation.

---

## Trial state

**Files:** [`examples/subscription-state/`](../../examples/subscription-state/)

1. Why return `nil` instead of `.introductoryOffer` when user has active subscription?
   - Expected: no trial UI — nil means “do not show”.

2. What is the priority order for paywall campaigns (JSON vs remote config vs fallback)?
   - Expected: old experiment JSON → pricing experiment cohort → remote campaign string → native intro offer.

3. Why an enum instead of flags on a ViewModel?
   - Expected: ADR 003 — combinatorial clarity, exhaustive tests.

---

## Survey flow

**Files:** [`examples/survey-flow/`](../../examples/survey-flow/)

1. Who owns branching — client or server?
   - Expected: server sends rules; client validates and resolves next ID for UX (button title, local validation).

2. How do you keep “Other” last when randomizing options?
   - Expected: partition + shuffle non-other, append other options.

3. Where would analytics events go?
   - Expected: above `SurveyService`, in coordinator/ViewModel — not in API mapper.

---

## Code style & process

**Files:** [`docs/CodeStyle.md`](../CodeStyle.md)

1. Why avoid `Equatable` on production errors just for tests?
2. When is `if/else if` preferred over sequential `guard`?
3. Why `mockPackage` naming instead of `getPackageResult`?

---

## Meta

1. What would you **not** put in a hiring repo from production?
   - Expected: API keys, full app, proprietary business rules tied to brand.

2. How does audio background relate to consumer app engineering?
   - Expected: [`docs/Evolution.md`](../Evolution.md) — session/state/interruption patterns.

---

## Suggested reading order for interview prep

1. README skill map  
2. `examples/deep-link` tests  
3. `docs/decisions/001`  
4. `examples/async-policy` tests  
5. `docs/features/post-trial-survey.md`  
6. `docs/Evolution.md`
