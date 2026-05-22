//
//  Created by Andrey Dubenkov on 26/06/2019
//  Copyright © 2019 . All rights reserved.
//

import Foundation
import RealmSwift

final class InvitesViewModel: Equatable {
    let invitesSegmentControlItems: [String]
    let invitesSegmentControlSelectedItemIndex: Int
    let inviteCellModels: [InviteCellModel]

    let isLoading: Bool
    let isAcceptingInvite: Bool
    let isResendingInvite: Bool
    let isDecliningInvite: Bool

    init(state: InvitesState) {
        isLoading = state.isLoading
        isAcceptingInvite = state.isAcceptingInvite
        isResendingInvite = state.isResendingInvite
        isDecliningInvite = state.isDecliningInvite

        let inviteKinds = InviteKind.allCases
        invitesSegmentControlItems = inviteKinds.map { $0.title }

        switch state.dataSourceKind {
        case .receivedInvites:
            invitesSegmentControlSelectedItemIndex = inviteKinds.firstIndex(of: .received) ?? 0
        case .sentInvites:
            invitesSegmentControlSelectedItemIndex = inviteKinds.firstIndex(of: .sent) ?? 0
        }

        inviteCellModels = InviteCellModelsFactory.makeCellModels(state: state)
    }

    static func == (lhs: InvitesViewModel, rhs: InvitesViewModel) -> Bool {
        return lhs.invitesSegmentControlItems == rhs.invitesSegmentControlItems &&
               lhs.invitesSegmentControlSelectedItemIndex == rhs.invitesSegmentControlSelectedItemIndex &&
               lhs.inviteCellModels == rhs.inviteCellModels &&
               lhs.isLoading == rhs.isLoading &&
               lhs.isAcceptingInvite == rhs.isAcceptingInvite &&
               lhs.isResendingInvite == rhs.isResendingInvite &&
               lhs.isDecliningInvite == rhs.isDecliningInvite
    }
}
