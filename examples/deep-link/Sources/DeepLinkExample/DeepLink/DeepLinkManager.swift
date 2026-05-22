import Foundation

enum DeepLinkError: Error {
    case invalidUrl
    case userNotLoggedIn
}

protocol DeepLinkManaging: AnyObject {
    var pendingDeepLink: DeepLink? { get }
    var observableDeepLink: Observable<DeepLink?> { get }
    var observableError: Observable<DeepLinkError?> { get }

    func handle(notification: PushNotification)
    func handle(context: DeepLinkContext) -> Bool
    func clearPendingDeepLink()
}
