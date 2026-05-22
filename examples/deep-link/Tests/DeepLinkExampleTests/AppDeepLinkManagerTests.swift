import XCTest
import UIKit

@testable import DeepLinkExample

final class AppDeepLinkManagerTests: XCTestCase {
    private var subject: AppDeepLinkManager!
    private var userSessionManager: MockUserSessionManager!
    private var attributionService: MockAttributionService!

    override func setUp() {
        super.setUp()
        userSessionManager = MockUserSessionManager()
        attributionService = MockAttributionService()
        subject = AppDeepLinkManager(attributionService: attributionService, userSessionManager: userSessionManager)
    }

    override func tearDown() {
        subject = nil
        userSessionManager = nil
        attributionService = nil
        super.tearDown()
    }
}

extension AppDeepLinkManagerTests {
    func testDeferredLinkFromBrowsingWebUserActivityRoutesResolvedURL() throws {
        userSessionManager.isLoggedIn = true
        let resolvedURL = try XCTUnwrap(URL(string: "https://example.app/article/123"))
        attributionService.mockResolvedDeepLink = AttributionDeepLink(url: resolvedURL, isDeferred: false)
        let activity = createBrowsingWebActivity(url: URL(string: "https://link.example.app/XYZ/foo"))
        let context = createDeepLinkContext(userActivity: activity)

        let handled = subject.handle(context: context)

        XCTAssertTrue(handled)
        XCTAssertEqual(subject.pendingDeepLink?.type, .article)
        XCTAssertEqual(subject.pendingDeepLink?.id, "123")
    }

    func testDeferredLinkFromOpenURLRoutesResolvedURL() throws {
        userSessionManager.isLoggedIn = true
        let resolvedURL = try XCTUnwrap(URL(string: "https://example.app/article/123"))
        attributionService.mockResolvedDeepLink = AttributionDeepLink(url: resolvedURL, isDeferred: false)
        let openURL = try XCTUnwrap(URL(string: "https://link.example.app/XYZ/foo"))
        let context = createDeepLinkContext(openURL: openURL, options: [:])

        let handled = subject.handle(context: context)

        XCTAssertTrue(handled)
        XCTAssertEqual(subject.pendingDeepLink?.type, .article)
        XCTAssertEqual(subject.pendingDeepLink?.id, "123")
    }

    func testDeferredLinkResolverEmitsNilDoesNotRouteAndDoesNotEmitError() {
        userSessionManager.isLoggedIn = true
        var errors: [DeepLinkError?] = []
        _ = subject.observableError.subscribe(onNext: { errors.append($0) })
        let activity = createBrowsingWebActivity(url: URL(string: "https://link.example.app/XYZ/foo"))
        let context = createDeepLinkContext(userActivity: activity)

        let handled = subject.handle(context: context)

        XCTAssertTrue(handled)
        XCTAssertNil(subject.pendingDeepLink)
        XCTAssertTrue(errors.isEmpty)
    }

    func testTrackingLinkFromBrowsingWebUserActivityRoutesResolvedURL() throws {
        userSessionManager.isLoggedIn = true
        let resolvedURL = try XCTUnwrap(URL(string: "https://example.app/article/123"))
        attributionService.mockResolvedDeepLink = AttributionDeepLink(url: resolvedURL, isDeferred: false)
        let activity = createBrowsingWebActivity(url: URL(string: "https://track.example.app/xyz/foo"))
        let context = createDeepLinkContext(userActivity: activity)

        let handled = subject.handle(context: context)

        XCTAssertTrue(handled)
        XCTAssertEqual(subject.pendingDeepLink?.type, .article)
        XCTAssertEqual(subject.pendingDeepLink?.id, "123")
    }

    func testDeferredLinkResolverEmitsUnparseableURLDoesNotRouteAndDoesNotEmitError() throws {
        userSessionManager.isLoggedIn = true
        let resolvedURL = try XCTUnwrap(URL(string: "https://unknown.example/"))
        attributionService.mockResolvedDeepLink = AttributionDeepLink(url: resolvedURL, isDeferred: false)
        var errors: [DeepLinkError?] = []
        _ = subject.observableError.subscribe(onNext: { errors.append($0) })
        let activity = createBrowsingWebActivity(url: URL(string: "https://link.example.app/XYZ/foo"))
        let context = createDeepLinkContext(userActivity: activity)

        let handled = subject.handle(context: context)

        XCTAssertTrue(handled)
        XCTAssertNil(subject.pendingDeepLink)
        XCTAssertTrue(errors.isEmpty)
    }
}

extension AppDeepLinkManagerTests {
    func testBrowsingWebUserActivityWithValidDeepLinkRoutesImmediately() {
        userSessionManager.isLoggedIn = true
        let activity = createBrowsingWebActivity(url: URL(string: "https://example.app/article/123"))
        let context = createDeepLinkContext(userActivity: activity)

        let handled = subject.handle(context: context)

        XCTAssertTrue(handled)
        XCTAssertEqual(subject.pendingDeepLink?.type, .article)
        XCTAssertEqual(subject.pendingDeepLink?.id, "123")
    }

    func testBrowsingWebUserActivityWithUnparseableURLEmitsInvalidUrl() {
        userSessionManager.isLoggedIn = true
        var errors: [DeepLinkError?] = []
        _ = subject.observableError.subscribe(onNext: { errors.append($0) })
        let activity = createBrowsingWebActivity(url: URL(string: "https://example.app/"))
        let context = createDeepLinkContext(userActivity: activity)

        let handled = subject.handle(context: context)

        XCTAssertFalse(handled)
        guard case .invalidUrl = errors.first ?? nil else {
            return XCTFail("Expected .invalidUrl")
        }
        XCTAssertNil(subject.pendingDeepLink)
    }

    func testBrowsingWebUserActivityWithNilWebpageURLEmitsInvalidUrl() {
        userSessionManager.isLoggedIn = true
        var errors: [DeepLinkError?] = []
        _ = subject.observableError.subscribe(onNext: { errors.append($0) })
        let activity = createBrowsingWebActivity(url: nil)
        let context = createDeepLinkContext(userActivity: activity)

        let handled = subject.handle(context: context)

        XCTAssertFalse(handled)
        guard case .invalidUrl = errors.first ?? nil else {
            return XCTFail("Expected .invalidUrl")
        }
        XCTAssertNil(subject.pendingDeepLink)
    }
}

extension AppDeepLinkManagerTests {
    func testOpenURLNonDeferredLinkValidDeepLinkRoutesImmediately() throws {
        userSessionManager.isLoggedIn = true
        let openURL = try XCTUnwrap(URL(string: "https://example.app/article/123"))
        let context = createDeepLinkContext(openURL: openURL, options: [:])

        let handled = subject.handle(context: context)

        XCTAssertTrue(handled)
        XCTAssertEqual(subject.pendingDeepLink?.type, .article)
        XCTAssertEqual(subject.pendingDeepLink?.id, "123")
    }

    func testOpenURLNonDeferredLinkUnparseableURLReturnsFalseWithoutError() throws {
        userSessionManager.isLoggedIn = true
        var errors: [DeepLinkError?] = []
        _ = subject.observableError.subscribe(onNext: { errors.append($0) })
        let openURL = try XCTUnwrap(URL(string: "https://example.app/"))
        let context = createDeepLinkContext(openURL: openURL, options: [:])

        let handled = subject.handle(context: context)

        XCTAssertFalse(handled)
        XCTAssertTrue(errors.isEmpty)
        XCTAssertNil(subject.pendingDeepLink)
    }
}

extension AppDeepLinkManagerTests {
    func testUserNotLoggedInEmitsUserNotLoggedInAndCachesPendingDeepLink() {
        userSessionManager.isLoggedIn = false
        var errors: [DeepLinkError?] = []
        _ = subject.observableError.subscribe(onNext: { errors.append($0) })
        let activity = createBrowsingWebActivity(url: URL(string: "https://example.app/article/123"))
        let context = createDeepLinkContext(userActivity: activity)

        _ = subject.handle(context: context)

        guard case .userNotLoggedIn = errors.first ?? nil else {
            return XCTFail("Expected .userNotLoggedIn")
        }
        XCTAssertEqual(subject.pendingDeepLink?.type, .article)
        XCTAssertEqual(subject.pendingDeepLink?.id, "123")
    }
}

extension AppDeepLinkManagerTests {
    func testHandleNotificationWithURLActionRoutesDeepLink() throws {
        userSessionManager.isLoggedIn = true
        let notification = try XCTUnwrap(PushNotification(userInfo: [
            "action": "openUrl",
            "url": "https://example.app/article/123"
        ]))

        subject.handle(notification: notification)

        XCTAssertEqual(subject.pendingDeepLink?.type, .article)
        XCTAssertEqual(subject.pendingDeepLink?.id, "123")
    }

    func testHandleNotificationWithEventActionRoutesPushNotificationArticle() throws {
        userSessionManager.isLoggedIn = true
        let notification = try XCTUnwrap(PushNotification(userInfo: [
            "action": "openEvent",
            "eventId": "evt-1"
        ]))

        subject.handle(notification: notification)

        XCTAssertEqual(subject.pendingDeepLink?.type, .pushNotificationArticle)
        XCTAssertEqual(subject.pendingDeepLink?.id, "evt-1")
    }
}

extension AppDeepLinkManagerTests {
    func testClearPendingDeepLinkResetsValue() {
        userSessionManager.isLoggedIn = true
        let activity = createBrowsingWebActivity(url: URL(string: "https://example.app/article/123"))
        let context = createDeepLinkContext(userActivity: activity)
        _ = subject.handle(context: context)
        XCTAssertNotNil(subject.pendingDeepLink)

        subject.clearPendingDeepLink()

        XCTAssertNil(subject.pendingDeepLink)
    }
}

extension AppDeepLinkManagerTests {
    private func createDeepLinkContext(userActivity: NSUserActivity) -> DeepLinkContext {
        return UserActivityDeepLinkContext(userActivity: userActivity)
    }

    private func createDeepLinkContext(
        openURL: URL,
        options: [UIApplication.OpenURLOptionsKey: Any]
    ) -> DeepLinkContext {
        return OpenURLDeepLinkContext(url: openURL, options: options)
    }

    private func createBrowsingWebActivity(url: URL?) -> NSUserActivity {
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = url
        return activity
    }
}
