import UIKit
import Intents

struct OpenURLDeepLinkContext {
    let url: URL
    let options: [UIApplication.OpenURLOptionsKey: Any]
}

extension OpenURLDeepLinkContext: DeepLinkContext {
    var attributedURL: URL? {
        return url
    }

    var intent: INIntent? {
        return nil
    }

    var isBrowsingWebUserActivity: Bool {
        return false
    }

    var isOpenURLSource: Bool {
        return true
    }

    var userActivity: NSUserActivity? {
        return nil
    }

    var openURLOptions: [UIApplication.OpenURLOptionsKey: Any] {
        return options
    }
}
