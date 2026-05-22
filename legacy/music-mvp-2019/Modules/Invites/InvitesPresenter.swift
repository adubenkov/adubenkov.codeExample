//
//  Created by Andrey Dubenkov on 26/06/2019
//  Copyright © 2019 . All rights reserved.
//

import AudioKit
import Foundation
import RealmSwift

final class InvitesPresenter {

    typealias Dependencies =
        HasRealmService &
        HasLoginService &
        HasReachabilityService &
        HasSyncService &
        HasApiService &
        HasCacheService &
        HasAudioPlaybackService &
        HasAnalyticsService

    weak var view: InvitesViewInput?
    weak var output: InvitesModuleOutput?

    var state: InvitesState

    private let dependencies: Dependencies
    private var invitesNotificationToken: NotificationToken?
    private lazy var realm: Realm = dependencies.realmService.makeDefaultRealm()

    init(state: InvitesState, dependencies: Dependencies) {
        self.state = state
        self.dependencies = dependencies
        state.currentUserID = dependencies.loginService.userID
        dependencies.audioPlaybackService.output = self
    }

    deinit {
        invitesNotificationToken?.invalidate()
    }

    // MARK: - Private

    private func fetchCachedInvitesInBackground(completion: @escaping () -> Void) {
        state.isLoading = true
        update(animated: false)
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                return
            }
            let fetchResult = self.fetchCachedInvites()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                let realm = self.realm
                self.state.sentInvites = realm.resolve(fetchResult.sentInvitesReference)
                self.state.receivedInvites = realm.resolve(fetchResult.receivedInvitesReference)
                self.state.isLoading = false
                self.update(animated: true)
                self.observeInviteChanges()
                completion()
            }
        }
    }

    private func fetchCachedInvites() -> InvitesFetchResult {
        let sentInvites = dependencies.realmService.getSentInvites()
        let receivedInvites = dependencies.realmService.getReceivedInvites(includeAcceptedInvites: true)
        return InvitesFetchResult(
            sentInvitesReference: ThreadSafeReference(to: sentInvites),
            receivedInvitesReference: ThreadSafeReference(to: receivedInvites)
        )
    }

    private func observeInviteChanges() {
        invitesNotificationToken?.invalidate()
        invitesNotificationToken = nil
        invitesNotificationToken = state.currentInvites?.observe { [weak self] change in
            guard let self = self else {
                return
            }
            switch change {
            case .initial:
                break
            case .update:
                self.update(animated: false)
            case .error(let error):
                self.output?.invitesModule(self, didFailWith: error)
            }
        }
    }

    private func syncInvites(completion: (() -> Void)? = nil) {
        if dependencies.reachabilityService.isReachable {
            dependencies.syncService.syncNewRemoteObjects(completion: completion)
        } else {
            completion?()
        }
    }

    private func resendInvite(withID inviteID: Int) {

        if let invite = self.invite(withID: inviteID) {
            resendInvite(invite)
        } else {
            let message = "Invite not found"
            output?.invitesModule(self, didFailWith: InvitesModuleError.inviteNotResent(message: message))
        }
    }

    private func acceptInvite(withID inviteID: Int) {
        state.pendingOperation = nil

        guard dependencies.realmService.canUserParticipateInNewProjects() else {
            state.pendingOperation = .acceptInvite(inviteID: inviteID)
            output?.invitesModuleDidRequestUpgradeSubscription(self)
            return
        }

        guard let invite = self.invite(withID: inviteID) else {
            let message = "Invite not found"
            output?.invitesModule(self, didFailWith: InvitesModuleError.inviteNotAccepted(message: message))
            return
        }

        acceptInvite(invite)
    }

    private func declineInvite(withID inviteID: Int) {
        state.pendingOperation = nil

        guard let invite = self.invite(withID: inviteID) else {
            let message = "Invite not found"
            output?.invitesModule(self, didFailWith: InvitesModuleError.inviteNotDeclined(message: message))
            return
        }

        declineInvite(invite)
    }

    private func resendInvite(_ invite: Invite) {
        state.isResendingInvite = true
        update(animated: false)
        dependencies.apiService.resendInvite(withID: invite.id) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success:
                self.dependencies.analyticsService.trackInviteResent(withID: invite.id)
                self.completeInviteResending(for: invite)
            case .failure(let error):
                self.state.isResendingInvite = false
                self.update(animated: false)
                self.output?.invitesModule(self, didFailWith: error)
            }
        }
    }

    private func acceptInvite(_ invite: Invite) {
        state.isAcceptingInvite = true
        update(animated: false)
        dependencies.apiService.activateInvite(withID: invite.id) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success:
                self.completeInviteAccepting(for: invite)
            case .failure(let error):
                self.state.isAcceptingInvite = false
                self.update(animated: false)
                self.output?.invitesModule(self, didFailWith: error)
            }
        }
    }

    private func declineInvite(_ invite: Invite) {
        state.isDecliningInvite = true
        update(animated: false)
        dependencies.apiService.declineInvite(withID: invite.id) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success:
                self.completeInviteDeclining(for: invite)
            case .failure(let error):
                self.state.isDecliningInvite = false
                self.update(animated: false)
                self.output?.invitesModule(self, didFailWith: error)
            }
        }
    }

    private func completeInviteAccepting(for invite: Invite) {
        let realm = dependencies.realmService.makeDefaultRealm()
        dependencies.realmService.updateProjectChangeDate(
            projectID: invite.projectID,
            changeDate: Date(),
            using: realm
        )
        realm.writeSafe {
            invite.isActive = false
        }
        syncInvites { [weak self] in
            guard let self = self else {
                return
            }
            self.output?.invitesModuleDidAcceptInvite(self)
            self.state.isAcceptingInvite = false
            self.update(animated: false)
        }
    }

    private func completeInviteDeclining(for invite: Invite) {
        let realm = dependencies.realmService.makeDefaultRealm()
        dependencies.realmService.updateProjectChangeDate(
            projectID: invite.projectID,
            changeDate: Date(),
            using: realm
        )
        realm.writeSafe {
            invite.isActive = false
        }
        syncInvites { [weak self] in
            guard let self = self else {
                return
            }
            self.output?.invitesModuleDidDeclineInvite(self)
            self.state.isDecliningInvite = false
            self.update(animated: false)
        }
    }

    private func completeInviteResending(for invite: Invite) {
        let realm = dependencies.realmService.makeDefaultRealm()
        dependencies.realmService.updateProjectChangeDate(
            projectID: invite.projectID,
            changeDate: Date(),
            using: realm
        )
        syncInvites { [weak self] in
            guard let self = self else {
                return
            }
            self.output?.invitesModuleDidResendInvite(self)
            self.state.isResendingInvite = false
            self.update(animated: false)
        }
    }

    private func invite(withID inviteID: Int) -> Invite? {
        return state.currentInvites?.first { $0.id == inviteID }
    }

    private func handlePlaybackEvent(forInviteWithID inviteID: Int) {
        guard !state.isLoadingTrack else {
            return
        }

        if inviteID == state.selectedForPlaybackInviteID, state.isPlayingTrack {
            stopProjectTrackPlayback()
            return
        }

        if state.selectedForPlaybackInviteID == inviteID,
            state.isPlayingTrack {
            dependencies.audioPlaybackService.stop()
            dependencies.audioPlaybackService.finishPlaybackSession()
            state.isPlayingTrack = false
            update(animated: false)
        } else {
            playProjectTrack(forInviteWithID: inviteID)
        }
    }

    private func playProjectTrack(forInviteWithID inviteID: Int) {
        resetProjectTrackPlayback()

        guard let invite = self.invite(withID: inviteID),
              let track = invite.details?.projectTrack else {
            let message = "Track not found"
            let error = InvitesModuleError.playbackFailure(message: message)
            output?.invitesModule(self, didFailWith: error)
            return
        }

        state.selectedForPlaybackInviteID = invite.id
        playProjectTrack(track)
    }

    private func playProjectTrack(_ track: Media) {
        state.isLoadingTrack = true
        update(animated: false)

        let cacheService = dependencies.cacheService
        cacheService.getAudioFile(forMediaWithID: track.id) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .failure(let error):
                self.resetProjectTrackPlayback()
                self.output?.invitesModule(self, didFailWith: error)
            case .success(let audioFile):
                self.state.isLoadingTrack = false
                self.playProjectTrack(using: audioFile.url)
            }
        }
    }

    private func playProjectTrack(using audioFileURL: URL) {
        do {
            try dependencies.audioPlaybackService.startPlaybackSession(withAudioFileURL: audioFileURL)
            try dependencies.audioPlaybackService.play()
            state.isPlayingTrack = true
            update(animated: false)
        } catch {
            resetProjectTrackPlayback()
            let message = "Unable to play project track from invite"
            output?.invitesModule(self, didFailWith: InvitesModuleError.playbackFailure(message: message))
        }
    }

    private func resetProjectTrackPlayback() {
        dependencies.audioPlaybackService.stop()
        dependencies.audioPlaybackService.finishPlaybackSession()
        state.selectedForPlaybackInviteID = nil
        state.isPlayingTrack = false
        state.isLoadingTrack = false
        update(animated: false)
    }

    private func stopProjectTrackPlayback() {
        guard state.isPlayingTrack else {
            return
        }

        dependencies.audioPlaybackService.stop()
        dependencies.audioPlaybackService.finishPlaybackSession()
        state.isPlayingTrack = false
        update(animated: false)
    }
}

// MARK: - InvitesViewOutput

extension InvitesPresenter: InvitesViewOutput {
    func viewDidLoad() {
        fetchCachedInvitesInBackground { [weak self] in
            self?.syncInvites()
        }
        update(animated: false)
    }

    func dataSourceChangeEventTriggered() {
        stopProjectTrackPlayback()
        switch state.dataSourceKind {
        case .receivedInvites:
            state.dataSourceKind = .sentInvites
        case .sentInvites:
            state.dataSourceKind = .receivedInvites
        }
        update(animated: true)
        observeInviteChanges()
    }

    func menuEventTriggered() {
        stopProjectTrackPlayback()
        output?.invitesModuleDidRequestShowSideMenu(self)
    }

    func acceptEventTriggered(with inviteID: Int) {
        stopProjectTrackPlayback()
        acceptInvite(withID: inviteID)
    }

    func declineEventTriggered(with inviteID: Int) {
        stopProjectTrackPlayback()
        declineInvite(withID: inviteID)
    }

    func resendEventTriggered(with inviteID: Int) {
        stopProjectTrackPlayback()
        resendInvite(withID: inviteID)
    }

    func playbackEventTriggered(with inviteID: Int) {
        handlePlaybackEvent(forInviteWithID: inviteID)
    }
}

// MARK: - InvitesModuleInput

extension InvitesPresenter: InvitesModuleInput {

    func update(animated: Bool) {
        let viewModel = InvitesViewModel(state: state)
        view?.update(with: viewModel, animated: animated)
    }

    func continueInviteAccepting() {
        guard let pendingOperation = state.pendingOperation else {
            return
        }

        switch pendingOperation {
        case .acceptInvite(let inviteID):
            acceptInvite(withID: inviteID)
        }
    }
}

// MARK: - AudioPlaybackServiceOutput

extension InvitesPresenter: AudioPlaybackServiceOutput {

    func audioPlaybackServiceDidFinishPlayback(_ service: AudioPlaybackServiceProtocol) {
        service.finishPlaybackSession()
        state.isPlayingTrack = false
        update(animated: false)
    }
}

// MARK: - InvitesFetchResult

private final class InvitesFetchResult {
    let sentInvitesReference: ThreadSafeReference<Results<Invite>>
    let receivedInvitesReference: ThreadSafeReference<Results<Invite>>

    init(sentInvitesReference: ThreadSafeReference<Results<Invite>>,
         receivedInvitesReference: ThreadSafeReference<Results<Invite>>) {
        self.sentInvitesReference = sentInvitesReference
        self.receivedInvitesReference = receivedInvitesReference
    }
}

// MARK: - InvitesModuleError

private enum InvitesModuleError {
    case inviteNotAccepted(message: String)
    case inviteNotDeclined(message: String)
    case inviteNotResent(message: String)
    case playbackFailure(message: String)
}

extension InvitesModuleError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .inviteNotAccepted(let message):
            return message
        case .inviteNotResent(let message):
            return message
        case .playbackFailure(let message):
            return message
        case .inviteNotDeclined(message: let message):
            return message
        }
    }
}
