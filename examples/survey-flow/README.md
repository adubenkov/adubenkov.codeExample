# Survey Flow Example

Sanitized excerpt of post-trial survey work: typed questions, async service, branching navigator, and flow controller without UIKit.

## Run tests

```bash
cd examples/survey-flow
swift test
```

## Highlights

- `SurveyService` protocol with async API mapping
- `SurveyQuestionNavigator` — pure branching from `nextRules` / `nextDefault`
- `SurveyFlowController` — load / answer / advance with validation
- Option randomization keeps `"other"` last

## Related

- Feature brief: [`docs/features/post-trial-survey.md`](../../docs/features/post-trial-survey.md)
- Interview questions: [`docs/InterviewWalkthrough.md`](../../docs/InterviewWalkthrough.md)
