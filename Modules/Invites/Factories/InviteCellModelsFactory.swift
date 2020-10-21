//
//  InviteCellModelsFactory.swift
//  
//
//  Created by Andrey Dubenkov on 28/06/2019.
//  Copyright © 2019 . All rights reserved.
//

import Foundation
import RealmSwift

enum InviteCellModelsFactory {
    static func makeCellModels(state: InvitesState) -> [InviteCellModel] {
        guard let currentUserID = state.currentUserID,
              let invites = state.currentInvites else {
            return []
        }

        return invites.map { invite in
            let inviteKind: InviteKind
            if invite.userID == currentUserID {
                inviteKind = .sent
            } else {
                inviteKind = .received
            }

            var isLoadingTrack = false
            var isPlayingTrack = false
            if state.selectedForPlaybackInviteID == invite.id {
                isLoadingTrack = state.isLoadingTrack
                isPlayingTrack = state.isPlayingTrack
            }

            return InviteCellModel(
                invite: invite,
                inviteKind: inviteKind,
                isLoadingTrack: isLoadingTrack,
                isPlayingTrack: isPlayingTrack
            )
        }
    }
}
