import UIKit

protocol AttributionService: AnyObject {
    var resolvedDeepLink: Observable<AttributionDeepLink?> { get }

    func resolveAttributionForUserActivity(_ userActivity: NSUserActivity)
    func resolveAttributionForOpenURL(url: URL, options: [UIApplication.OpenURLOptionsKey: Any])
}
