//
//  Created by Andrey Dubenkov on 30/07/2020
//  Copyright © 2020 . All rights reserved.
//
import FirebaseAnalytics

typealias Dependencies = HasAnalyticsService

private let dependencies: Dependencies = ServiceContainer()

final class AnalyticsService: AnalyticsServiceProtocol {

    func trackCommentPosted(withID id: Int) {
        Analytics.logEvent("comment_posted", parameters: [
            "id": id as NSObject
        ])
    }

    func trackInviteSent(withID id: Int) {
        Analytics.logEvent("invite_sent", parameters: [
            "id": id as NSObject
        ])
    }

    func trackInviteResent(withID id: Int) {
        Analytics.logEvent("invite_resent", parameters: [
            "id": id as NSObject
        ])
    }

    func trackInviteAccepted(withID id: Int) {
        Analytics.logEvent("invite_accepted", parameters: [
            "id": id as NSObject
        ])
    }

    func trackProjectCreated(withID id: Int, name: String) {
        Analytics.logEvent("project_created", parameters: [
            "name": name as NSObject,
            "id": id as NSObject
        ])
    }

    func trackTakeAdded(withID takeID: Int, projectID: Int) {
        Analytics.logEvent("take_added", parameters: [
            "id": takeID as NSObject,
            "projectID": projectID as NSObject
        ])
    }

    func trackRecordingAdded(withProjectID projectID: Int) {
        Analytics.logEvent("recording_added_to_project", parameters: [
            "projectID": projectID as NSObject
        ])
    }

    func trackProjectAccessed(withProjectID projectID: Int) {
        Analytics.logEvent("project_accessed", parameters: [
            "id": projectID as NSObject
        ])
    }

    func trackTakeAccessed(withTakeID takeID: Int) {
        Analytics.logEvent("take_accessed", parameters: [
            "id": takeID as NSObject
        ])
    }

    func trackTakeShared(withTakeID takeID: Int) {
        Analytics.logEvent("take_shared", parameters: [
            "id": takeID as NSObject
        ])
    }
}
