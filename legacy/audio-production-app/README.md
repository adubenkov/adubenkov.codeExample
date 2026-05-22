# Audio production app (2016–2019)

Production iOS app from a long-term outsourcing engagement (~4,000 hours). Real-time audio recording, playback, and collaboration workflows.

## Why it is here

This legacy code demonstrates early modular architecture that evolved into the service-layer patterns in `examples/`. It also backs the **audio processing** niche from my CV (AudioKit, AVFoundation, Core Audio).

## Patterns

- Module composition: `*Module`, `*Presenter`, `*ViewModel`, `State/`
- Dependency injection via `Has*` protocol composition (`Services/Services.swift`)
- StoreKit subscriptions, Realm-backed invites, URL-based deep links
- Audio session lifecycle, playback, and recording services

## Start here (audio)

| File | Shows |
|---|---|
| `Services/AudioSession/AudioSessionService.swift` | AVAudioSession category / interruption handling |
| `Services/AudioPlayback/AudioPlaybackService.swift` | Playback orchestration |
| `Modules/Recorder/RecorderPresenter.swift` | Recording state, background work |
| `Services/Services.swift` | Protocol-composed DI container |

## Start here (architecture)

| File | Shows |
|---|---|
| `Modules/Subscriptions/SubscriptionsPresenter.swift` | StoreKit purchase flow |
| `Services/DeepLinkManager.swift` | Early URL routing (compare with `examples/deep-link/`) |
| `Modules/Invites/InvitesPresenter.swift` | Realm observers + reactive state |

For modern production patterns, start with [`examples/deep-link/`](../../examples/deep-link/) instead.
