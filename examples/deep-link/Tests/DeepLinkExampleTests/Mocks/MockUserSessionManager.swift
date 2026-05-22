import Foundation

@testable import DeepLinkExample

final class MockUserSessionManager: UserSessionManaging {
    var isLoggedIn: Bool = false
}
