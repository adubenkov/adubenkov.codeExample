# Feature brief: Alternative sources carousel

Sanitized summary of a horizontal content carousel module (anonymized). No proprietary content IDs or designs.

## Problem

Surface alternative content sources for an item in a horizontal carousel with paywall CTA, loading/error states, and analytics — tied to subscription tier and user policy.

## Constraints

- Content from dedicated API endpoint; cache-friendly for repeat detail-screen visits.
- Paywall CTA visibility depends on subscription + policy flags.
- Error and empty states must not break detail-screen layout.
- iPhone and iPad width classes (production UI).

## Architecture

```
AlternativeSourcesContentService (async)
    → UserPolicyService + SubscriptionService (gates)
    → ViewModel (state: loading / loaded / error / empty)
    → Compositional layout carousel (production UI)
    → Analytics at ViewModel boundary
```

- **Service:** fetch + map; no UIKit.
- **ViewModel:** exposes immutable state struct for UI binding.
- **Paywall CTA:** driven by policy + subscription read models, not hard-coded in cell.

## Trade-offs

| Choice | Rationale |
|---|---|
| Dedicated content service | Detail screen stays thin; testable mapping |
| Policy-gated CTA | Aligns with server-driven entitlements |
| Explicit error state | Avoid infinite spinners on partial failures |

## Outcome

Shipped carousel with paywall integration and analytics. Part of a larger detail-screen redesign that went through platform design review.

## Related code in this repo

- Policy reads: [`examples/async-policy/`](../../examples/async-policy/)
- Subscription state: [`examples/subscription-state/`](../../examples/subscription-state/)

## Interview questions

- How do policy and subscription interact when they disagree?
- Where do loading states live — service or ViewModel?
- How would you snapshot-test carousel layout without production assets?
