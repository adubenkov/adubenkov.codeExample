# Subscription State Example

Sanitized excerpt of subscription trial-state resolution: remote config cohorts, promotional offers, feature-flag payloads, and paywall routing as pure testable logic.

## Run tests

```bash
cd examples/subscription-state
swift test
```

## Highlights

- `TrialState` resolves intro offer vs promotional offer vs external paywall campaign from many inputs
- Remote configuration and pricing experiment matching without UI or StoreKit
- Representative unit tests for guard conditions and experiment priority
