import XCTest

@testable import DeepLinkExample

final class DeepLinkTypeTests: XCTestCase {
    func testInitWithKnownFirstPathComponentReturnsType() {
        XCTAssertEqual(DeepLinkType(firstPathComponent: "article", secondPathComponent: nil, isAppLink: false), .article)
    }

    func testInitWithUnknownFirstPathComponentReturnsNil() {
        XCTAssertNil(DeepLinkType(firstPathComponent: "unknown", secondPathComponent: nil, isAppLink: false))
    }

    func testInitAppLinkWithKnownSecondPathComponentReturnsType() {
        XCTAssertEqual(DeepLinkType(firstPathComponent: "applink", secondPathComponent: "article", isAppLink: true), .article)
    }

    func testInitAppLinkWithUnknownSecondPathComponentReturnsNil() {
        XCTAssertNil(DeepLinkType(firstPathComponent: "applink", secondPathComponent: "unknown", isAppLink: true))
    }

    func testInitAppLinkWithNilSecondPathComponentReturnsNil() {
        XCTAssertNil(DeepLinkType(firstPathComponent: "applink", secondPathComponent: nil, isAppLink: true))
    }

    func testArticleRequiresAuth() {
        XCTAssertTrue(DeepLinkType.article.requiresAuth)
    }

    func testAuthDoesNotRequireAuth() {
        XCTAssertFalse(DeepLinkType.auth.requiresAuth)
    }

    func testRedeemDoesNotRequireAuth() {
        XCTAssertFalse(DeepLinkType.redeem.requiresAuth)
    }

    func testMagicLinkAuthenticationDoesNotRequireAuth() {
        XCTAssertFalse(DeepLinkType.magicLinkAuthentication.requiresAuth)
    }
}
