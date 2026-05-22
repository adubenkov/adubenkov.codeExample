//
//  Created by Andrey Dubenkov on 10/11/2019
//  Copyright © 2019 . All rights reserved.
//

import AVFoundation
import AudioKit
import AudioKitUI

final class ProjectHubPresenter {

    typealias Dependencies = HasRecordHubAudioServiceService &
                             HasRealmService &
                             HasCacheService &
                             HasReachabilityService &
                             HasSyncService &
                             HasAnalyticsService

    weak var view: ProjectHubViewInput?
    weak var visualisationView: ProjectHubVisualisationViewInput?
    weak var output: ProjectHubModuleOutput?

    var state: ProjectHubState

    private let dependencies: Dependencies

    init(state: ProjectHubState, dependencies: Dependencies) {
        self.state = state
        self.dependencies = dependencies
        dependencies.recordHubAudioServiceService.output = self
    }

    // MARK: - Private

    private func chargeProject(_ id: Int?) {
        guard let id = id,
              let project = dependencies.realmService.getProject(withID: id),
              let media = project.track else {
            return
        }
        state.isMyProject = project.isMyProject
        state.isLoading = true
        update(animated: true)
        dependencies.cacheService.getAudioFile(forMediaWithID: media.id) { result in
            switch result {
            case .failure(let error):
                self.state.isLoading = false
                self.update(animated: true)
                self.view?.showError(error)
                return
            case .success(let file):
                self.dependencies.recordHubAudioServiceService.startRecordingSession(withProjectTrackFile: file, takeFile: nil)
                self.state.isLoading = false
                self.update(animated: true)
            }
        }
    }

    private func setMusicVolume(_ volume: Float) {
        dependencies.recordHubAudioServiceService.setMusicPlayerVolume(volume)
    }

    private func setClipVolume(_ volume: Float) {

    }

    private func makeNewTake(_ name: String, completion: @escaping (_ takeID: Int) -> Void) {
        guard let projectID = state.projectID else {
            return
        }

        state.isLoading = true
        update(animated: true)

        let temporaryTakeID = UUID().hashValue
        let newTake = Take()
        newTake.id = temporaryTakeID
        newTake.name = name
        newTake.projectID = projectID
        newTake.userID = LoginManager.sharedInstance.userID
        newTake.createdAt = Date()
        newTake.updatedAt = Date()
        newTake.tempRealmID = temporaryTakeID
        newTake.notSyncedCreate = true

        dependencies.realmService.saveTake(newTake) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success:
                let realm = self.dependencies.realmService.makeDefaultRealm()
                self.dependencies.realmService.updateProjectChangeDate(projectID: projectID, changeDate: Date(), using: realm)
                self.dependencies.syncService.syncNewLocalObjects(completion: { _, _ in
                    self.dependencies.syncService.syncNewRemoteObjects {
                        guard let syncedTake = self.dependencies.realmService.getTake(tempRealmID: temporaryTakeID) else {
                            return
                        }
                        self.state.isLoading = false
                        self.update(animated: true)
                        completion(syncedTake.id)
                    }
                }, noInternet: {
                    self.state.isLoading = false
                    self.update(animated: true)
                    completion(temporaryTakeID)
                })
            case .failure(let error):
                self.view?.showError(error)
            }
        }
    }

    private func getNameDialog() -> UIAlertController {
        let questionDialog = UIAlertController(title: "", message: "Please input take title", preferredStyle: .alert)
        questionDialog.addTextField { textField in
            let formatter = DateFormatter(withFormat: "yyyy-MM-dd HH:mm:ss", locale: "UTC")
            textField.text = formatter.string(from: Date())
        }
        questionDialog.addAction(UIAlertAction(title: "Set", style: .default) { _ in
            guard let name = questionDialog.textFields?[0].text else {
                return
            }
            self.makeNewTake(name) { newTakeID in
                NotificationCenter.default.post(name: .goToTake, object: (self.state.projectID, newTakeID))
            }
        })
        questionDialog.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
        })
        return questionDialog
    }

    private func getWaveFormData() {
        if let (data, duration) = dependencies.recordHubAudioServiceService.getTrackWaveformData() {
            visualisationView?.addMusicPlot(duration: duration, data: data)
        }
    }
}

// MARK: - ProjectHubViewOutput

extension ProjectHubPresenter: ProjectHubViewOutput {
    func backButtonPressed() {
        dependencies.recordHubAudioServiceService.stopRecordSession()
        self.view?.exit()
    }

    func viewWillAppear() {
        chargeProject(state.projectID)
        dependencies.analyticsService.trackProjectAccessed(withProjectID: state.projectID ?? 0)
    }

    func newButtonPressed() {
        view?.showDialog(getNameDialog())
    }

    func playButtonPressed() {
        let isPlaying = dependencies.recordHubAudioServiceService.isPlaying
        state.isPlaying = !isPlaying
        dependencies.recordHubAudioServiceService.setTime(position: state.currentTime ?? 0.0)
        dependencies.recordHubAudioServiceService.playPressed()
        update(animated: true)
    }

    func rewindButtonPressed() {
        dependencies.recordHubAudioServiceService.rewind()
    }

    func volumeButtonPressed() {
        state.isVolumePanelOpen = !state.isVolumePanelOpen
        update(animated: true)
    }

    func vocalSliderValueChanged(value: Float) {
        setClipVolume(value)
    }

     func musicSliderValueChanged(value: Float) {
        setMusicVolume(value)
    }

    func viewDidLoad() {
        update(animated: false)
    }

    func viewWillDisapear() {
    }
}

    // MARK: - RecordHubAudioServiceServiceOutput

extension ProjectHubPresenter: RecordHubAudioServiceServiceOutput {

    func sessionInterrupted() {
        state.isPlaying = false
        update(animated: true)
    }

    func sessionInterruptionEnded() {
    }

    func renderingProgress(progress: Double) {

    }

    func exportViewReady(view: UIViewController) {
    }

    func recordStarted(position: Double) {
    }

    func recordEnded() {
    }

    func lastClipRemoved(_ clips: [AKFileClip]) {
    }

    func filesRecorded(files: [AKFileClip]) {
    }

    func sequenceCanUndo(_ can: Bool) {
    }

    func recordPlotReady(plot: AKNodeOutputPlot) {
    }

    func playerInitStarted() {
        state.isLoading = true
        update(animated: true)
    }

    func playerIsReady() {
        getWaveFormData()
        state.isLoading = false
        update(animated: true)
    }

    func didHandledAnError(error: RecordHubError) {
        guard error.type != .cantStartAudioSession else {
            view?.showMessage(" is unavailable while on a phone call", title: "Error") {
                self.view?.exit()
            }
            return
        }
        view?.showError(error)
        self.view?.exit()
    }

    func playheadPosition(position: Double) {
        if !state.isScrubbing {
            state.currentTime = position
            update(animated: true)
            visualisationView?.playhead(contentOffset: position)
        }
    }

    func fileEnded() {
        state.isPlaying = false
        update(animated: true)
    }
}

// MARK: - ProjectHubVisualisationViewOutput
extension ProjectHubPresenter: ProjectHubVisualisationViewOutput {
    var input: ProjectHubVisualisationViewInput? {
        get {
            return visualisationView
        }
        set {
            visualisationView = newValue
        }
    }

    func scrollViewDidScrollToOffset(position: Double) {
        state.currentTime = position
        update(animated: true)
    }

    func scrollViewWillBeginDragging() {
        state.isScrubbing = true
    }

    func scrollViewWillEndDragging() {
        if dependencies.recordHubAudioServiceService.isPlaying {
            state.wasPlayed = true
        }
    }

    func scrollViewDidEndDraggingAt(position: Double) {
        state.isScrubbing = false
        dependencies.recordHubAudioServiceService.setTime(position: position)
        if state.wasPlayed {
            state.wasPlayed = false
            dependencies.recordHubAudioServiceService.stopPlayback()
            dependencies.recordHubAudioServiceService.playPressed()
        }
    }

    func scrollViewDidEndDecelerating(position: Double) {
        state.currentTime = position
        update(animated: true)
    }
}

// MARK: - ProjectHubModuleInput

extension ProjectHubPresenter: ProjectHubModuleInput {
    func update(animated: Bool) {
        let viewModel = ProjectHubViewModel(state: state)
        view?.update(with: viewModel, animated: animated)
    }
}
