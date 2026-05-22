//
//  Created by Andrey Dubenkov on 30/07/2020
//  Copyright © 2020 . All rights reserved.
//

protocol HasAnalyticsService {
    var analyticsService: AnalyticsServiceProtocol { get }
}

protocol AnalyticsServiceProtocol: class {
    func trackCommentPosted(withID id: Int)
    func trackInviteSent(withID id: Int)
    func trackInviteResent(withID id: Int)
    func trackInviteAccepted(withID id: Int)
    func trackProjectCreated(withID id: Int, name: String)
    func trackTakeAdded(withID takeID: Int, projectID: Int)
    func trackRecordingAdded(withProjectID projectID: Int)
    func trackProjectAccessed(withProjectID projectID: Int)
    func trackTakeAccessed(withTakeID takeID: Int)
    func trackTakeShared(withTakeID takeID: Int)
}
