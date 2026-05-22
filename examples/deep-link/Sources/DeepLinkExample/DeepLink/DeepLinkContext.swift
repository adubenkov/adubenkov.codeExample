import UIKit
import Intents

protocol DeepLinkContext {
    var attributedURL: URL? { get }
    var intent: INIntent? { get }
    var isBrowsingWebUserActivity: Bool { get }
    var isOpenURLSource: Bool { get }
    var userActivity: NSUserActivity? { get }
    var openURLOptions: [UIApplication.OpenURLOptionsKey: Any] { get }
}
