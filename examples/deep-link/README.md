# Deep Link Example

Sanitized excerpt from production deep-link routing: protocol-driven entry contexts, attribution resolution, auth gating, and unit tests.

## Run tests

```bash
cd examples/deep-link
swift test
```

## Highlights

- `DeepLinkContext` unifies universal links, custom URL schemes, and intents
- `AppDeepLinkManager` delegates deferred links to `AttributionService` without vendor-specific method names
- `PushNotification` parsing for notification-driven routes
- Tests follow grouped setup / action / assertion layout from `docs/CodeStyle.md`
