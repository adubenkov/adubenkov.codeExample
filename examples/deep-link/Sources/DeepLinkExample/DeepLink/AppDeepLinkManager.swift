import Foundation
import UIKit
import Intents

final class AppDeepLinkManager: DeepLinkManaging {
    private let attributionService: AttributionService
    private let userSessionManager: UserSessionManaging
    private let variableDeepLink = Variable<DeepLink?>(nil)
    let observableError = Observable<DeepLinkError?>()

    var observableDeepLink: Observable<DeepLink?> {
        return variableDeepLink.asObservable()
    }

    var pendingDeepLink: DeepLink? {
        return variableDeepLink.value
    }

    init(attributionService: AttributionService, userSessionManager: UserSessionManaging) {
        self.attributionService = attributionService
        self.userSessionManager = userSessionManager
        setupBindings()
    }

    private func setupBindings() {
        _ = attributionService.resolvedDeepLink.subscribe(onNext: { [weak self] attributionDeepLink in
            self?.handleResolved(attributionDeepLink: attributionDeepLink)
        })
    }

    private func handleResolved(attributionDeepLink: AttributionDeepLink?) {
        guard let deepLink = generate(deepLink: attributionDeepLink?.url) else {
            return
        }
        route(deepLink: deepLink)
    }

    func handle(context: DeepLinkContext) -> Bool {
        if context.intent != nil {
            return true
        }
        if shouldResolve(context: context) {
            resolve(context: context)
            return true
        }
        if context.isBrowsingWebUserActivity {
            guard let deepLink = generate(deepLink: context.attributedURL) else {
                observableError.on(.next(.invalidUrl))
                return false
            }
            route(deepLink: deepLink)
            return true
        }
        if context.isOpenURLSource, let deepLink = generate(deepLink: context.attributedURL) {
            route(deepLink: deepLink)
            return true
        }
        return false
    }

    func handle(notification: PushNotification) {
        guard let deepLink = generate(deepLink: notification) else {
            return
        }
        route(deepLink: deepLink)
    }

    func clearPendingDeepLink() {
        variableDeepLink.value = nil
    }

    private func route(deepLink: DeepLink) {
        guard userSessionManager.isLoggedIn else {
            observableError.on(.next(.userNotLoggedIn))
            variableDeepLink.value = deepLink
            return
        }
        variableDeepLink.value = deepLink
    }

    private func generate(deepLink from: URL?) -> DeepLink? {
        guard let url = from else {
            return nil
        }

        if isMagicLinkAuthDeepLink(from: url) {
            return DeepLink(type: .magicLinkAuthentication, url: url, id: nil)
        }

        guard let firstPathComponent = url.pathComponents.item(at: 1) else {
            return nil
        }

        let secondPathComponent = url.pathComponents.item(at: 2)
        let isAppLink = firstPathComponent == "applink"
        let id = isAppLink ? nil : secondPathComponent

        if let type = DeepLinkType(firstPathComponent: firstPathComponent, secondPathComponent: secondPathComponent, isAppLink: isAppLink) {
            return DeepLink(type: type, url: url, id: id)
        }

        guard !isAppLink else {
            return nil
        }

        guard let sourceType = url.queryValueOf(parameterName: "source") else {
            return DeepLink(type: .pushNotificationUrl, url: url, id: nil)
        }

        guard let type = DeepLinkType(firstPathComponent: sourceType, secondPathComponent: nil, isAppLink: isAppLink) else {
            return nil
        }
        return DeepLink(type: type, url: url, id: firstPathComponent)
    }

    private func isMagicLinkAuthDeepLink(from url: URL) -> Bool {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let linkParam = components.queryItems?
                .first(where: { $0.name == "link" })?
                .value,
            let decodedInnerUrl = linkParam.removingPercentEncoding,
            let actionUrl = URL(string: decodedInnerUrl),
            let actionUrlComponents = URLComponents(url: actionUrl, resolvingAgainstBaseURL: false),
            let continueURLString = actionUrlComponents.queryItems?
                .first(where: { $0.name == "continueUrl" })?
                .value,
            let mode = actionUrlComponents.queryItems?
                .first(where: { $0.name == "mode" })?
                .value
        else {
            return false
        }

        return continueURLString == MagicLinkAuthenticationConstants.actionContinueURLString && mode == "signIn"
    }

    private func generate(deepLink from: PushNotification) -> DeepLink? {
        if from.action == .url, let url = from.url, let deepLink = generate(deepLink: URL(string: url)) {
            return deepLink
        }

        if from.action == .url, let url = from.url {
            return DeepLink(type: .pushNotificationUrl, url: URL(string: url), id: nil)
        }

        if from.action == .event, let id = from.eventID {
            return DeepLink(type: .pushNotificationArticle, url: nil, id: id)
        }

        return nil
    }

    private func shouldResolve(context: DeepLinkContext) -> Bool {
        guard let host = context.attributedURL?.host else {
            return false
        }
        return [AttributionConstants.DeferredLinkHost, AttributionConstants.TrackingLinkHost].contains(host)
    }

    private func resolve(context: DeepLinkContext) {
        if let userActivity = context.userActivity {
            attributionService.resolveAttributionForUserActivity(userActivity)
        } else if let url = context.attributedURL {
            attributionService.resolveAttributionForOpenURL(url: url, options: context.openURLOptions)
        }
    }
}
