import Foundation

enum DeepLinkType: String {
    case article
    case profile
    case settings
    case discover
    case auth
    case redeem
    case subscribe
    case pushNotificationArticle = "openEvent"
    case pushNotificationUrl = "openUrl"
    case magicLinkAuthentication

    var requiresAuth: Bool {
        return self != .auth && self != .redeem && self != .magicLinkAuthentication
    }

    var hasId: Bool {
        switch self {
        case .article, .pushNotificationArticle: return true
        case .profile, .settings, .discover, .auth, .redeem, .subscribe, .pushNotificationUrl, .magicLinkAuthentication: return false
        }
    }

    init?(firstPathComponent: String, secondPathComponent: String?, isAppLink: Bool) {
        if let secondPathComponent = secondPathComponent, isAppLink {
            self.init(rawValue: secondPathComponent)
        } else {
            self.init(rawValue: firstPathComponent)
        }
    }
}

struct DeepLink {
    let url: URL?
    let type: DeepLinkType
    let id: String?

    init(type: DeepLinkType, url: URL?, id: String?) {
        self.type = type
        self.url = url
        self.id = id
    }
}
