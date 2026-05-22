import UIKit
import Intents

struct UserActivityDeepLinkContext {
    let userActivity: NSUserActivity?
}

extension UserActivityDeepLinkContext: DeepLinkContext {
    var attributedURL: URL? {
        return userActivity?.webpageURL
    }

    var intent: INIntent? {
        return userActivity?.interaction?.intent
    }

    var isBrowsingWebUserActivity: Bool {
        return userActivity?.activityType == NSUserActivityTypeBrowsingWeb
    }

    var isOpenURLSource: Bool {
        return false
    }

    var openURLOptions: [UIApplication.OpenURLOptionsKey: Any] {
        return [:]
    }
}
