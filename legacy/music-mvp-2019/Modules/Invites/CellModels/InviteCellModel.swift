//
//  InviteCellModel.swift
//  
//
//  Created by Andrey Dubenkov on 26/06/2019.
//  Copyright © 2019 . All rights reserved.
//

import SwiftDate
import UIKit.UIImage

final class InviteCellModel: Equatable {
    let inviteID: Int
    let collaboratorPhotoURL: URL?
    let inviteTitle: String
    let inviteDateString: String
    let inviteStatusString: String?

    let projectName: String
    let projectTimeString: String
    let projectTempoString: String
    let projectKeyString: String
    let projectNote: String?

    let isInviteAcceptActionHidden: Bool
    let isInviteResendActionHidden: Bool
    let isInviteDeclineActionHidden: Bool
    let isLoadingTrack: Bool
    let isPlayingTrack: Bool

    init(invite: Invite,
         inviteKind: InviteKind,
         isLoadingTrack: Bool,
         isPlayingTrack: Bool) {
        inviteID = invite.id

        if let inviteDate = invite.createdAt {
            inviteDateString = type(of: self).inviteDateString(for: inviteDate)
        } else {
            inviteDateString = "Unknown"
        }

        self.isLoadingTrack = isLoadingTrack
        self.isPlayingTrack = isPlayingTrack

        guard let inviteDetails = invite.details else {
            inviteTitle = "Unknown"
            collaboratorPhotoURL = nil
            isInviteAcceptActionHidden = true
            isInviteResendActionHidden = true
            isInviteDeclineActionHidden = true
            inviteStatusString = nil
            projectName = "Unknown"
            projectTimeString = "Unknown"
            projectTempoString = "Unknown"
            projectKeyString = "Unknown"
            projectNote = nil
            return
        }

        switch inviteKind {
        case .received:
            inviteTitle = "From: \(inviteDetails.ownerName)"
            collaboratorPhotoURL = inviteDetails.ownerPhoto?.fileURL
            isInviteAcceptActionHidden = !invite.isActive
            isInviteDeclineActionHidden = !invite.isActive
            isInviteResendActionHidden = true
            inviteStatusString = nil
        case .sent:
            collaboratorPhotoURL = inviteDetails.inviteePhoto?.fileURL
            inviteTitle = "To: \(inviteDetails.inviteeName)"
            isInviteAcceptActionHidden = true
            isInviteDeclineActionHidden = true
            isInviteResendActionHidden = !invite.isActive
            inviteStatusString = invite.isActive ? "Pending" : "Accepted"
        }

        projectName = inviteDetails.projectName
        projectTimeString = inviteDetails.projectTimeSignature
        projectTempoString = "\(inviteDetails.projectTempo)BPM"
        projectKeyString = inviteDetails.projectKey
        projectNote = inviteDetails.projectNote
    }

    static func == (lhs: InviteCellModel, rhs: InviteCellModel) -> Bool {
        return lhs.inviteID == rhs.inviteID &&
               lhs.collaboratorPhotoURL == rhs.collaboratorPhotoURL &&
               lhs.inviteTitle == rhs.inviteTitle &&
               lhs.inviteDateString == rhs.inviteDateString &&
               lhs.inviteStatusString == rhs.inviteStatusString &&
               lhs.projectName == rhs.projectName &&
               lhs.projectTimeString == rhs.projectTimeString &&
               lhs.projectTempoString == rhs.projectTempoString &&
               lhs.projectKeyString == rhs.projectKeyString &&
               lhs.projectNote == rhs.projectTempoString &&
               lhs.isInviteAcceptActionHidden == rhs.isInviteAcceptActionHidden &&
               lhs.isInviteResendActionHidden == rhs.isInviteResendActionHidden &&
               lhs.isLoadingTrack == rhs.isLoadingTrack &&
               lhs.isPlayingTrack == rhs.isPlayingTrack &&
               lhs.isInviteDeclineActionHidden == rhs.isInviteDeclineActionHidden
    }

    // MARK: - Private

    private static func inviteDateString(for date: Date) -> String {
        let localDate = date.in(region: .local)
        if localDate.isToday {
            return "Today"
        } else if localDate.isYesterday {
            return "Yesterday"
        } else {
            return localDate.toString(.date(.short))
        }
    }
}
