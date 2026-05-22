//
//  Created by Andrey Dubenkov on 26/06/2019
//  Copyright © 2019 . All rights reserved.
//

import Foundation
import RealmSwift

enum InvitesPendingOperation {
    case acceptInvite(inviteID: Int)
}

final class InvitesState {
    var currentUserID: Int?

    var dataSourceKind: InvitesDataSourceKind = .sentInvites
    var receivedInvites: Results<Invite>?
    var sentInvites: Results<Invite>?

    var isLoading: Bool = false
    var isAcceptingInvite: Bool = false
    var isDecliningInvite: Bool = false
    var isResendingInvite: Bool = false

    var pendingOperation: InvitesPendingOperation?

    var isLoadingTrack: Bool = false
    var isPlayingTrack: Bool = false
    var selectedForPlaybackInviteID: Int?

    var currentInvites: Results<Invite>? {
        switch dataSourceKind {
        case .receivedInvites:
            return receivedInvites
        case .sentInvites:
            return sentInvites
        }
    }
}

enum InvitesDataSourceKind {
    case receivedInvites
    case sentInvites
}
