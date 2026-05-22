import UIKit

@testable import DeepLinkExample

final class MockAttributionService: AttributionService {
    private let resolvedDeepLinkVariable = Variable<AttributionDeepLink?>(nil)
    var mockResolvedDeepLink: AttributionDeepLink?

    var resolvedDeepLink: Observable<AttributionDeepLink?> {
        return resolvedDeepLinkVariable.asObservable()
    }

    func resolveAttributionForUserActivity(_ userActivity: NSUserActivity) {
        resolvedDeepLinkVariable.value = mockResolvedDeepLink
    }

    func resolveAttributionForOpenURL(url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) {
        resolvedDeepLinkVariable.value = mockResolvedDeepLink
    }
}
