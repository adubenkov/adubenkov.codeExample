# Examples index

Sanitized excerpts from recent product work (2024–2026, anonymized). Each folder is a standalone Swift package.

| Package | Run tests | Docs |
|---|---|---|
| [deep-link](deep-link/) | `cd deep-link && swift test` | [ADR 001](../docs/decisions/001-deeplink-attribution-boundary.md) |
| [subscription-state](subscription-state/) | `cd subscription-state && swift test` | [ADR 003](../docs/decisions/003-trial-state-pure-enum.md) |
| [async-policy](async-policy/) | `cd async-policy && swift test` | [ADR 002](../docs/decisions/002-user-policy-protocol-extraction.md) |
| [survey-flow](survey-flow/) | `cd survey-flow && swift test` | [Feature brief](../docs/features/post-trial-survey.md) |

Run all: [`../scripts/test-all.sh`](../scripts/test-all.sh)
