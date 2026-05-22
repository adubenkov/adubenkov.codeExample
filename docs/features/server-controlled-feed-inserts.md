# Feature brief: Server-Controlled Feed Inserts

Sanitized summary of feed insert work (anonymized). Logic described; no proprietary feed IDs.

## Problem

Marketing and product need to pin promotional or editorial cards into feeds at server-defined positions — different per feed type, subscription tier, and experiments.

## Constraints

- Insert definitions from remote config / API — not hard-coded in ViewModels.
- Must not break pagination or diffable snapshot stability.
- Respect user policy limits (e.g. carousel interaction caps).
- Graceful no-op when insert payload malformed.

## Architecture

```
FeedContentService
    → UserPolicyService (limits / feature gates)
    → Remote insert model
    → FeedSection builder
    → DiffableDataSource snapshot
```

- **Policy gating:** `UserPolicyService.isEnabled` / `limitFor` before rendering interactive inserts.
- **Pure mapping:** insert DTO → view model item; invalid rows dropped in mapper, not in cells.
- **Analytics:** impression / tap events at presentation layer, not in mapper.

## Trade-offs

| Choice | Rationale |
|---|---|
| Server-controlled positions | Ops can tune without release |
| Drop malformed inserts | Fail safe on partial API responses |
| Policy checks in service not cell | Single source of truth for limits |

## Outcome

Shipped inserts across multiple feed types with experiment cohorts. Reduced duplicate insert logic in ViewControllers.

## Related code in this repo

- Policy gating: [`examples/async-policy/`](../../examples/async-policy/)
- Experiment-style state: [`examples/subscription-state/`](../../examples/subscription-state/)

## Interview questions

- How do inserts interact with pagination cursors?
- Where do you validate insert payload vs silently skip?
- How would you test snapshot composition without UI tests?
