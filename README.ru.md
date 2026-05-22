# adubenkov.codeExample

Подборка Swift iOS примеров для найма — production-паттерны, тесты и инженерные стандарты.  
**Продолжение резюме:** [LinkedIn](https://www.linkedin.com/in/adubenkov/) · [GitHub](https://github.com/adubenkov/adubenkov.codeExample)

## Обо мне

iOS-разработчик, 10+ лет (продукт + freelance). С 2022 — consumer subscription app (iPhone/iPad, deep links, feature flags, extensions). Ранее ~4 000 часов на production-приложении с AudioKit. Участие в team code style guide.

Репозиторий содержит **обезличенные excerpt'ы** — архитектуру, domain logic и тесты. Без названий работодателя и продукта, ключей API и проприетарной логики.

Также: BLE, SwiftUI (freelance), Widget / NotificationService extensions, subscription и attribution SDK (здесь только абстракции).

---

## С чего начать

| Аудитория | Маршрут | Время |
|---|---|---|
| Recruiter / HM | README → [`docs/Evolution.md`](docs/Evolution.md) → [`docs/CodeStyle.md`](docs/CodeStyle.md) | ~5 мин |
| iOS peer | [`examples/deep-link/`](examples/deep-link/) → [`examples/async-policy/`](examples/async-policy/) | ~15 мин |
| Architect | ADR → [`docs/features/`](docs/features/) → [`docs/InterviewWalkthrough.md`](docs/InterviewWalkthrough.md) | ~30 мин |

---

## Карта навыков (резюме → репозиторий)

| Навык / работа | Где смотреть |
|---|---|
| Style guide | [`docs/CodeStyle.md`](docs/CodeStyle.md) |
| Deep linking & attribution | [`examples/deep-link/`](examples/deep-link/) |
| Подписки / эксперименты | [`examples/subscription-state/`](examples/subscription-state/) |
| UserPolicy async refactor | [`examples/async-policy/`](examples/async-policy/) |
| Post-Trial Survey | [`examples/survey-flow/`](examples/survey-flow/) |
| Feed Inserts / Alternative sources | [`docs/features/`](docs/features/) |
| AudioKit (~4 000h) | [`legacy/audio-production-app/`](legacy/audio-production-app/) |
| Эволюция 2013→2026 | [`docs/Evolution.md`](docs/Evolution.md) |

---

## Примеры (Swift PM + тесты)

```bash
./scripts/test-all.sh
```

| Пакет | Что показывает |
|---|---|
| [`deep-link`](examples/deep-link/) | Routing, attribution boundary, auth gate |
| [`subscription-state`](examples/subscription-state/) | TrialState, remote config |
| [`async-policy`](examples/async-policy/) | async/await, policy map |
| [`survey-flow`](examples/survey-flow/) | Survey branching, async flow |

---

## Документация

- [`docs/CodeStyle.md`](docs/CodeStyle.md) — конвенции code review
- [`docs/Evolution.md`](docs/Evolution.md) — timeline карьеры
- [`docs/decisions/`](docs/decisions/) — mini-ADR
- [`docs/features/`](docs/features/) — feature briefs
- [`docs/InterviewWalkthrough.md`](docs/InterviewWalkthrough.md) — вопросы для разбора

---

## Legacy

[`legacy/audio-production-app/`](legacy/audio-production-app/) — audio MVP 2016–2019.

---

**Andrey Dubenkov** · [hrnthrnt@gmail.com](mailto:hrnthrnt@gmail.com)  
English version: [`README.md`](README.md)
