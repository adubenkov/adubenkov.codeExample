# Feature brief: Post-Trial Survey

Sanitized summary of end-to-end survey work (2024–2025, anonymized). No proprietary API or copy.

## Problem

After trial conversion, collect structured feedback with branching questions, multi-select, free text, and server-driven search — without blocking the main navigation stack.

## Constraints

- Question flow defined server-side (`nextRules`, `nextDefault`).
- Multiple question types: select, multi-select, free-text, search.
- Required vs optional answers enforced before submit.
- Analytics on show / next / complete / error (event names sanitized in production).

## Architecture

```
SurveyFlowController
    → SurveyService (async protocol)
    → SurveyQuestionNavigator (pure branching)
    → UI layer (compositional layout + diffable data source in production)
```

- **Service layer:** maps API DTOs → `SurveyQuestion`, handles answer submission.
- **Navigator:** resolves next question ID from rules locally when needed for button titles / validation.
- **Controller:** orchestrates `load → answer → next` with async/await; no UIKit in service.

## Trade-offs

| Choice | Rationale |
|---|---|
| Server-driven branching | Product can change flows without app release |
| Pure navigator helper | Test branching without network |
| Randomize options in service | Keeps “Other” option last after shuffle |

## Outcome

Shipped post-trial survey with internal QA via Feature Preview Menu. Compositional collection layout in production; this repo includes **logic + tests only**.

## Code in this repo

- [`examples/survey-flow/`](../../examples/survey-flow/)

## Interview questions

- What happens if `nextRules` matches nothing and `nextDefault` is nil?
- How do you test required multi-select without UI tests?
- Where would you add analytics without coupling events to `SurveyService`?
