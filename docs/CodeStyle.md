# Code Style

Common code review conventions for Swift iOS development. Adapted from production team standards.

## Swift

### Prefer dictionary literals with compactMapValues

Prefer building dictionaries as a literal and removing `nil` via `compactMapValues`, instead of a local mutable `var` with multiple `if let`.

Good:

```swift
return [
    "QuestionId": question.id,
    "Version": question.version
].compactMapValues { $0 }
```

Bad:

```swift
var parameters: [String: Any] = [
    "QuestionId": question.id
]
if let version = question.version {
    parameters["Version"] = version
}
return parameters
```

### Avoid local mutable var when not reused

Prefer immutable values; avoid local `var` when it is not reassigned or used elsewhere.

Good:

```swift
return buildParameters(question: question)
```

Bad:

```swift
var parameters = buildParameters(question: question)
parameters = parameters.compactMapValues { $0 }
return parameters
```

### Avoid `private extension`

Prefer scoping at the method/property level instead of marking the entire extension as `private`.

Good:

```swift
extension MyType {
    private func createViewModel() -> ViewModel { /* ... */ }
}
```

Bad:

```swift
private extension MyType {
    func createViewModel() -> ViewModel { /* ... */ }
}
```

### Class layout order

Keep class members grouped and ordered for readability: stored properties, computed properties, init, public/internal methods, private methods.

Good:

```swift
final class SomeClass {
    private let isEnabled = true
    let isVisible = false
    var isDirty = false

    private var isValid: Bool { true }
    var summary: String { "ok" }

    init() { super.init() }

    func update() { isDirty = true }
    private func updateInternal() { isDirty = true }
}
```

Bad:

```swift
final class SomeClass {
    func update() { isDirty = true }
    private let isEnabled = true
    var summary: String { "ok" }
    init() { super.init() }
}
```

### Keep same-kind properties in one block

Do not separate consecutive stored properties with empty lines. Use blank lines only between sections or logical groups.

Good:

```swift
final class MockSubscriptionProvider {
    var mockPackage: Package?
    var mockActivePurchases: ActivePurchases?
    var mockPurchaseResult: PurchaseResult?
}
```

Bad:

```swift
final class MockSubscriptionProvider {
    var mockPackage: Package?

    var mockActivePurchases: ActivePurchases?

    var mockPurchaseResult: PurchaseResult?
}
```

### Separate computed properties with blank lines

Separate consecutive computed properties with a blank line. This is the inverse of stored properties, which are kept together without blank lines.

Good:

```swift
var attributedURL: URL? {
    return userActivity?.webpageURL
}

var intent: INIntent? {
    return userActivity?.interaction?.intent
}
```

Bad:

```swift
var attributedURL: URL? {
    return userActivity?.webpageURL
}
var intent: INIntent? {
    return userActivity?.interaction?.intent
}
```

### Prefer `final` classes by default

Classes should be `final` unless they are explicitly designed for subclassing (or require Obj-C/KVO overrides).

Good:

```swift
final class SomeClass {}
```

Bad:

```swift
class SomeClass {}
```

### One-liners in switch cases

If a switch case contains a single call, keep it inline with the case for readability.

Good:

```swift
switch state {
case .loading: showLoading()
case .loaded: render()
case .failed: showError()
}
```

Bad:

```swift
switch state {
case .loading:
    showLoading()
case .loaded:
    render()
case .failed:
    showError()
}
```

### Avoid omitting parameter labels

Prefer named parameters over `_` for clarity. Use `_` only when the label adds no value at call sites.

Good:

```swift
private func handleMultiSelect(item: SurveyQuestionItem) {}
```

Bad:

```swift
private func handleMultiSelect(_ item: SurveyQuestionItem) {}
```

### Always use explicit `return`

Always write an explicit `return` statement. Implicit single-expression returns should not be used — in computed properties, functions, or closures.

Good:

```swift
var isEnabled: Bool {
    return state == .active
}

func createTitle() -> String {
    return "Hello, \(name)"
}
```

Bad:

```swift
var isEnabled: Bool { state == .active }

func createTitle() -> String { "Hello, \(name)" }
```

### Multi-line `guard ... else`

Always put `return`/`break`/`continue` on a new line inside the `else` block. Inline `else { return }` is harder to spot in review.

Good:

```swift
guard let self else {
    return
}
guard self.isOnboarding else {
    self.dismissViewController.on(.next(()))
    return
}
```

Bad:

```swift
guard let self else { return }
guard self.isOnboarding else {
    self.dismissViewController.on(.next(()))
    return
}
```

### Prefer `if/else if/else` over sequential guards for branching logic

When conditions represent branches of the same decision (related states), use a single `if/else if/else` chain. Use `guard` only for unrelated preconditions.

Good:

```swift
if isOnboarding, let question = await loadQuestion(surveyId: id) {
    showSurvey(question: question)
} else if isOnboarding {
    completeOnboarding()
} else {
    dismiss()
}
```

Bad:

```swift
guard isOnboarding else {
    dismiss()
    return
}
if let question = await loadQuestion(surveyId: id) {
    showSurvey(question: question)
} else {
    completeOnboarding()
}
```

### Empty line before type declarations

Always add an empty line before `class`/`struct`/`enum`/`protocol` — even after swiftlint directives.

Good:

```swift
// swiftlint:disable file_length

class ViewControllerFactory {
```

Bad:

```swift
// swiftlint:disable file_length
class ViewControllerFactory {
```

### Inline `if let` when variable is used only once

If a variable is assigned and immediately checked with `if let`, combine them.

Good:

```swift
if let question = await loadQuestion(surveyId: id) {
    show(question: question)
}
```

Bad:

```swift
let question = await loadQuestion(surveyId: id)
if let question {
    show(question: question)
}
```

### Avoid trailing whitespace

Remove trailing spaces and tabs on every line.

### Avoid inline text comments

Prefer self-explanatory code; add text comments only in rare cases where intent cannot be made clear by naming or structure.

### Use `create` for factory methods

Prefer `create` over `make`/`build` for methods that construct and return new objects. Include the full type name for clarity.

Good:

```swift
private func createSurveyQuestionOptions(from response: Response) -> [SurveyQuestionOption] {}
```

Bad:

```swift
private func makeOptions(from response: Response) -> [SurveyQuestionOption] {}
```

### Prefer "set" for setter-like methods

Use `set...` naming for methods that only assign or update a value/state.

Good:

```swift
private func setPlaceholder(text: String?) {}
```

Bad:

```swift
private func applyPlaceholder(text: String?) {}
```

### Mock storage naming in unit tests

In mocks, name backing storage with a `mock...` prefix and the domain meaning, not generic `...Results`.

Good:

```swift
private var mockFeatureFlags
private var mockPackage
private var mockActivePurchases
private var mockPurchaseResult
private var mockStringValues
private var mockNotifySubscriptionChangeError
```

Bad:

```swift
private var isEnabledResults
private var getPackageResult
private var getActivePurchasesResult
private var purchaseResult
private var stringResults
private var notifySubscriptionChangeError
```

### Don't add protocol conformances solely for unit tests

Don't add a protocol conformance (`Equatable`, `Hashable`, etc.) to a production type only to make a test assertion shorter. If the conformance has no production use, adapt the test instead. For enums, prefer `guard case` / `if case` pattern matching.

Good:

```swift
// Production
enum DeepLinkError: Error {
    case invalidUrl
    case userNotLoggedIn
}

// Test
guard case .invalidUrl = errors.first ?? nil else {
    return XCTFail("Expected .invalidUrl")
}
```

Bad:

```swift
// Production — Equatable added only so the test can use XCTAssertEqual on an array
enum DeepLinkError: Error, Equatable {
    case invalidUrl
    case userNotLoggedIn
}

// Test
XCTAssertEqual(errors, [.invalidUrl])
```

### Test class extensions only when setUp/tearDown exist

In unit tests, split test cases across extensions only when the class has `setUp`/`tearDown` (or other shared members) so the main class isn't left empty. For small test classes without lifecycle methods, keep all tests inside the main class itself.

Good (no `setUp`/`tearDown` — flat):

```swift
final class DeepLinkTypeTests: XCTestCase {
    func testInitWithKnownFirstPathComponentReturnsType() { /* ... */ }
    func testArticleRequiresAuth() { /* ... */ }
}
```

Good (has `setUp`/`tearDown` — grouped via extensions):

```swift
final class AppDeepLinkManagerTests: XCTestCase {
    override func setUp() { /* ... */ }
    override func tearDown() { /* ... */ }
}

extension AppDeepLinkManagerTests {
    func testDeferredLinkFromBrowsingWebUserActivityRoutesResolvedURL() throws { /* ... */ }
}
```

Bad (empty main class with extensions for a tiny test set):

```swift
final class DeepLinkTypeTests: XCTestCase {}

extension DeepLinkTypeTests {
    func testInitWithKnownFirstPathComponentReturnsType() { /* ... */ }
}
```

### Group setup in unit tests; separate action and assertion

In unit tests, keep all setup statements together without blank lines. Use blank lines only to separate the action and assertion sections so they stand out from setup.

Good:

```swift
func testDeferredLinkFromBrowsingWebUserActivityRoutesResolvedURL() throws {
    userSessionManager.isLoggedIn = true
    let resolvedURL = try XCTUnwrap(URL(string: "https://example.app/article/123"))
    attributionService.mockResolvedDeepLink = AttributionDeepLink(url: resolvedURL, isDeferred: false)
    let activity = createBrowsingWebActivity(url: URL(string: "https://link.example.app/XYZ/foo"))
    let context = createDeepLinkContext(userActivity: activity)

    let handled = subject.handle(context: context)

    XCTAssertTrue(handled)
    XCTAssertEqual(subject.pendingDeepLink?.type, .article)
}
```

Bad:

```swift
func testDeferredLinkFromBrowsingWebUserActivityRoutesResolvedURL() throws {
    userSessionManager.isLoggedIn = true
    let resolvedURL = try XCTUnwrap(URL(string: "https://example.app/article/123"))
    attributionService.mockResolvedDeepLink = AttributionDeepLink(url: resolvedURL, isDeferred: false)

    let activity = createBrowsingWebActivity(url: URL(string: "https://link.example.app/XYZ/foo"))
    let context = createDeepLinkContext(userActivity: activity)

    let handled = subject.handle(context: context)

    XCTAssertTrue(handled)
    XCTAssertEqual(subject.pendingDeepLink?.type, .article)
}
```

### Constants naming and grouping

Group related constants in a `struct` (not `enum` or bare `let`). Name constants in PascalCase. For type-scoped constants use a nested `struct Constants`; for shared constants use a standalone `struct <Domain>Constants` file.

Good:

```swift
// Standalone
struct NotificationConstants {
    static let KeepMeUpdated = "com.example.keepMeUpdated"
    static let FreeTrialReminder = "com.example.freeTrialReminder"
}

// Nested (type-scoped)
final class DeferredLinkAttributionService {
    struct Constants {
        static let DeferredLinkHost = "link.example.app"
    }
}
```

Bad:

```swift
private static let deferredLinkHost = "link.example.app"

enum NotificationConstants {
    static let keepMeUpdated = "com.example.keepMeUpdated"
}
```

### Protocol conformance in extensions

Place protocol implementations in a dedicated extension.

Good:

```swift
extension SomeClass: Protocol {}
```

Bad:

```swift
final class SomeClass: Protocol {}
```

### Don't leak vendor/implementation names through abstraction-level APIs

Types that depend on a protocol must not reference the concrete implementation (vendor, framework, or service name) in their own API — including private members. The concrete name belongs behind constants/extensions on the implementing type.

Good:

```swift
final class AppDeepLinkManager {
    private func shouldResolve(context: DeepLinkContext) -> Bool { ... }
    private func resolve(context: DeepLinkContext) { ... }
}
```

Bad:

```swift
final class AppDeepLinkManager {
    private func shouldHandleVendorDeferredLink(context: DeepLinkContext) -> Bool { ... }
    private func startVendorAttribution(context: DeepLinkContext) { ... }
}
```

### One type per file

Each protocol, class, struct, or enum lives in its own file named after the type. A type's conformance extensions stay in the same file as the type itself.

Good:

```
DeepLinkContext.swift              // protocol DeepLinkContext
UserActivityDeepLinkContext.swift  // struct + DeepLinkContext extension
OpenURLDeepLinkContext.swift       // struct + DeepLinkContext extension
```

Bad:

```
DeepLinkContext.swift              // protocol + both structs + both extensions
```
