//
//  DeepLinkManager.swift
//  
//
//  Created by Egor Kitselyuk on 21/01/2018.
//  Copyright © 2018 . All rights reserved.
//

import Foundation
import UIKit

enum DeepLinkType {
    case invites(hash: String)
    case take(projectID: Int, takeID: Int)
    case message(projectID: Int)
    case revokeAccess(projectID: Int)
    case projectLeaved(projectID: Int)
}

enum MessageInfoType: String {
    case link
    case hashCotained = "3"
    case projectContained = "4"
}

class DeeplinkParser {
    static let shared = DeeplinkParser()

    private init() { }

    func parseDeepLink(_ url: URL, hash: String? = nil) -> DeepLinkType? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let pathComponents = components.path.components(separatedBy: "/")
        if pathComponents[1] == "invites" {
            let urlHash = pathComponents[2]
            return DeepLinkType.invites(hash: urlHash)
        }

        switch pathComponents[2] {
        case "invites":
            if let hash = hash {
                return DeepLinkType.invites(hash: hash)
            }
        case "comments":
            if let projectID = Int(pathComponents[1]) {
                return DeepLinkType.message(projectID: projectID)
            }
        case "takes":
            if let projectID = Int(pathComponents[1]),
                let takeID = Int(pathComponents[3]) {
                return DeepLinkType.take(projectID: projectID, takeID: takeID)
            }
        default:
            break
        }
        return nil
    }
}

class DeeplinkNavigator {
    static let sharedInstance = DeeplinkNavigator()

    private init() {
    }

    func proceedToDeeplink(_ type: DeepLinkType) {
        switch type {
        case .invites(hash: let hash):
            NotificationCenter.default.post(name: .pushInvite, object: (hash))
        case .take(let projectID, let takeID):
            NotificationCenter.default.post(name: .pushTake, object: (projectID: projectID, takeID: takeID))
        case .message(projectID: let pID):
            NotificationCenter.default.post(name: .pushComment, object: (pID))
        case .revokeAccess(let pID):
            NotificationCenter.default.post(name: .pushRevokeAccess, object: (pID))
        case .projectLeaved(let pID):
            NotificationCenter.default.post(name: .pushProjectLeaved, object: (pID))
        }
    }
}

protocol DeepLinkManagerProtocol {
    func checkDeepLink(completion: @escaping (Result<Void, Error>) -> Void) throws
}

class DeepLinkManager: DeepLinkManagerProtocol {

    var deeplinkType: DeepLinkType?

    var showNotification = true

    static let sharedInstance = DeepLinkManager()
    private init() {}

    func checkDeepLink(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let type = deeplinkType else {
            return
        }
        if LoginManager.sharedInstance.loggedIn {
            DeeplinkNavigator.sharedInstance.proceedToDeeplink(type)
            completion(.success(()))
        } else {
            completion(.failure(DeepLinkManagerError.notLoggedIn))
        }
    }

    func handleDeeplink(url: URL, userInfo: [String: Any]? = nil) {
        func parseUserInfo(_ userInfo: [String: Any]?) -> (object: [String: Any], messageType: MessageInfoType?) {
            guard let userInfoDict = userInfo,
                let messageTypeString = userInfoDict["type"] as? String,
                let objectString = userInfoDict["object"] as? String,
                let data = objectString.data(using: .utf8),
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return ([:], nil)
            }
            return (json, MessageInfoType(rawValue: messageTypeString))
        }

        let info = parseUserInfo(userInfo)
        switch info.messageType {
        case .hashCotained:
            guard let hash = info.object["hash"] as? String else {
                deeplinkType = nil
                return
            }
            deeplinkType = DeeplinkParser.shared.parseDeepLink(url, hash: hash)
            return
        case .projectContained:
            guard let project = Project(JSON: info.object) else {
                deeplinkType = nil
                return
            }
            deeplinkType = DeepLinkType.revokeAccess(projectID: project.id)
            return
        case nil:
            deeplinkType = DeeplinkParser.shared.parseDeepLink(url)
            return
        default:
            let hash = info.object["hash"] as? String
            deeplinkType = DeeplinkParser.shared.parseDeepLink(url, hash: hash)
            return
        }
    }
}

private enum DeepLinkManagerError: Equatable {
    case notLoggedIn
}

extension DeepLinkManagerError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return "Please login to opent this link"
        }
    }
}
