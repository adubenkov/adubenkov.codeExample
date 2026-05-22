# Deep link routing: 2019 vs 2025

Side-by-side comparison of deep link handling in this repository.

## 2019 — legacy audio app

File: [`legacy/audio-production-app/Services/DeepLinkManager.swift`](../legacy/audio-production-app/Services/DeepLinkManager.swift)

| Aspect | Approach |
|---|---|
| Entry | Singleton `DeepLinkManager.sharedInstance` |
| Parsing | `DeeplinkParser` with hard-coded path indices |
| Navigation | `NotificationCenter.default.post` |
| Auth | Checked at proceed time, errors via `Result` |
| Tests | None |
| Vendor links | Not applicable |

```swift
class DeepLinkManager: DeepLinkManagerProtocol {
    static let sharedInstance = DeepLinkManager()
    // ...
    func checkDeepLink(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let type = deeplinkType else { return }
        if LoginManager.sharedInstance.loggedIn {
            DeeplinkNavigator.sharedInstance.proceedToDeeplink(type)
            completion(.success(()))
        } else {
            completion(.failure(DeepLinkManagerError.notLoggedIn))
        }
    }
}
```

**Problems at scale:** global mutable state, untestable routing, navigation decoupled via notifications, no attribution/deferred link boundary.

## 2025 — production pattern (sanitized)

File: [`examples/deep-link/Sources/DeepLinkExample/DeepLink/AppDeepLinkManager.swift`](../examples/deep-link/Sources/DeepLinkExample/DeepLink/AppDeepLinkManager.swift)

| Aspect | Approach |
|---|---|
| Entry | `DeepLinkContext` protocol (user activity, open URL) |
| Parsing | URL → typed `DeepLink` with auth metadata |
| Navigation | Pending deep link + error observables |
| Auth | Gate in `route(deepLink:)` with cached pending link |
| Tests | 20+ unit tests with mocks |
| Deferred links | `shouldResolve` / `resolve` via `AttributionService` protocol |

```swift
final class AppDeepLinkManager: DeepLinkManaging {
    private func shouldResolve(context: DeepLinkContext) -> Bool { ... }
    private func resolve(context: DeepLinkContext) { ... }

    private func route(deepLink: DeepLink) {
        guard userSessionManager.isLoggedIn else {
            observableError.on(.next(.userNotLoggedIn))
            variableDeepLink.value = deepLink
            return
        }
        variableDeepLink.value = deepLink
    }
}
```

## Migration principles

1. **Replace singletons with injected services** — testability first.
2. **Unify entry points** — one `handle(context:)` instead of separate URL / push / activity handlers scattered across app delegate.
3. **Hide vendors** — attribution host checks live in constants; manager methods stay vendor-neutral (`docs/decisions/001-deeplink-attribution-boundary.md`).
4. **Add tests before expanding routes** — new `DeepLinkType` cases get parsing + auth tests upfront.

## Related

- [`examples/deep-link/`](../examples/deep-link/)
- [`docs/decisions/001-deeplink-attribution-boundary.md`](decisions/001-deeplink-attribution-boundary.md)
