# Music collaboration MVP (2018–2019)

Early iOS modular architecture from a music collaboration product prototype.

## Patterns

- Module composition: `*Module`, `*Presenter`, `*ViewModel`, `State/`
- Dependency injection via `Has*` protocol composition (`Services.swift`)
- StoreKit subscriptions, Realm-backed invites, URL-based deep links
- Audio recording and playback services

## Notable files

- `Services/Services.swift` — service container with protocol composition
- `Modules/Subscriptions/SubscriptionsPresenter.swift` — subscription purchase flow
- `Services/DeepLinkManager.swift` — URL parsing and navigation routing

This code predates async/await and protocol-first service boundaries used in later production work under `examples/`.
