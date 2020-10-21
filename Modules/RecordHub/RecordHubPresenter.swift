//
import AudioKit
import AudioKitUI
//  Created by Andrey Dubenkov on 13/11/2019
//  Copyright © 2019 . All rights reserved.
//
import AVFoundation
import FileKit

final class RecordHubPresenter {
    typealias Dependencies = HasRealmService &
        HasCacheService &
        HasRecordHubAudioServiceService &
        HasReachabilityService &
        HasApiService &
        HasSyncService &
        HasAnalyticsService

    weak var view: RecordHubViewInput?
    weak var visualisationView: RecordHubVisualisationViewInput?
    weak var output: RecordHubModuleOutput?

    var state: RecordHubState

    private let dependencies: Dependencies

    init(state: RecordHubState, dependencies: Dependencies) {
        self.state = state
        self.dependencies = dependencies
        dependencies.recordHubAudioServiceService.output = self
    }

    // MARK: - Private

    private func requestRecordPermission() {
        let audioSession = AVAudioSession.sharedInstance()
        audioSession.requestRecordPermission { isAccessGranted in
            print("AVAudioSession - requested record permission for audio session:")
            print(isAccessGranted ? "Record access granted" : "Record access denied")
        }
    }

    private func chargeTake(project projectID: Int?, takeID: Int?) {
        guard let id = projectID,
            let project = dependencies.realmService.getProject(withID: id),
            let projectMedia = project.track else {
            return
        }

        func success(projectFile: AKAudioFile, takeFile: AKAudioFile?) {
            dependencies.recordHubAudioServiceService.output = self
            dependencies.recordHubAudioServiceService.startRecordingSession(withProjectTrackFile: projectFile, takeFile: takeFile)
            state.isLoading = false
            update(animated: true)
        }

        func failure(_ error: Error) {
            state.isLoading = false
            update(animated: true)
            view?.showError(error)
        }
        state.isLoading = true
        update(animated: true)
        dependencies.cacheService.getAudioFile(forMediaWithID: projectMedia.id) { result in
            switch result {
            case let .failure(error):
                failure(error)
            case let .success(projectFile):
                guard let takeID = takeID,
                    let take = self.dependencies.realmService.getTake(id: takeID),
                    let media = take.media else {
                    failure(TakeSavingError.invalidTake)
                    return
                }
                if media.isUrlHere {
                    self.state.isMyTake = take.isMyTake
                    self.dependencies.cacheService.getAudioFile(forMediaWithID: take.mediaID) { result in
                        switch result {
                        case let .failure(error):
                            failure(error)
                        case let .success(takeFile):
                            success(projectFile: projectFile, takeFile: takeFile)
                        }
                    }
                } else {
                    self.state.isMyTake = take.isMyTake
                    success(projectFile: projectFile, takeFile: nil)
                }
            }
        }
    }

    private func setMusicVolume(_ volume: Float) {
        dependencies.recordHubAudioServiceService.setMusicPlayerVolume(volume)
    }

    private func setClipVolume(_ volume: Float) {
        dependencies.recordHubAudioServiceService.setClipPlayerVolume(volume)
    }

    private func getWaveFormData() {
        if let (data, duration) = dependencies.recordHubAudioServiceService.getTrackWaveformData() {
            visualisationView?.addMusicPlot(duration: duration, data: data)
        }
    }

    private func getWaveFormDataForFirstClip() {
        if let (data, duartion, clip) = dependencies.recordHubAudioServiceService.getFirstClipkWaveformData() {
            visualisationView?.addVocalPlot(duration: clip.audioFile.duration,
                                            clipDuration: clip.duration,
                                            time: clip.time,
                                            offset: clip.offset,
                                            data: data,
                                            identifire: ObjectIdentifier(clip))
        }
    }

    private func shareTake(takeID: Int) {
        func success() {
            dependencies.analyticsService.trackTakeShared(withTakeID: takeID)
            view?.showMessage("Take Shared!", title: "Success") {
                self.dependencies.recordHubAudioServiceService.resetUndoCache()
                self.dependencies.recordHubAudioServiceService.rewind()
                self.chargeTake(project: self.state.projectID, takeID: self.state.takeID)
            }
        }

        func failure(error: Error) {
            view?.showError(error)
        }

        func syncChangesAndPublish() {
            dependencies.syncService.syncLocalObjectChanges {
                self.dependencies.apiService.publishTake(withID: takeID) { result in
                    switch result {
                    case let .failure(error):
                        failure(error: error)
                    case .success:
                        success()
                    }
                }
            }
        }

        func renderAudio() {
            dependencies.recordHubAudioServiceService.stopPlayback()
            state.isPlaying = false
            state.isRendering = true
            update(animated: true)

            dependencies.recordHubAudioServiceService.render(clipsOnly: true) { [weak self] url in
                guard let self = self else {
                    return
                }
                self.state.isRendering = false
                self.state.isUploading = true
                self.update(animated: true)
                self.saveTake(withTemporaryAudioFileURL: url) { result in
                    self.state.isUploading = false
                    self.update(animated: true)
                    switch result {
                    case .success:
                        syncChangesAndPublish()
                    case let .failure(error):
                        failure(error: error)
                    }
                }
            }
        }

        let isOnline = dependencies.reachabilityService.isReachable
        if isOnline {
            // Sharing take without audio
            guard dependencies.recordHubAudioServiceService.hasChanges else {
                syncChangesAndPublish()
                return
            }

            guard let take = self.dependencies.realmService.getTake(id: takeID) else {
                failure(error: TakeSavingError.invalidTake)
                return
            }

            if take.notSyncedCreate {
                dependencies.syncService.syncNewLocalObjects(completion: { _, _ in
                    renderAudio()
                }, noInternet: {
                    self.view?.showMessage("Can't share take in offline mode", title: "Offline mode", completion: nil)
                })
            } else {
                renderAudio()
            }
        } else {
            view?.showMessage("Can't share take in offline mode", title: "Offline mode", completion: nil)
        }
    }

    private func exportTake(clipsOnly: Bool) {
        state.isLoading = true
        update(animated: false)
        dependencies.recordHubAudioServiceService.render(clipsOnly: clipsOnly) { url in
            self.state.isLoading = false
            self.update(animated: false)

            let viewController = UIActivityViewController(activityItems: [url], applicationActivities: [])
            self.view?.presentView(view: viewController)
        }
    }

    private func getExportOptionDialog() -> UIAlertController {
        let optionMenu = UIAlertController(title: "Export", message: "Export full mixdown or vocals only?", preferredStyle: .actionSheet)
        let voiceOnly = UIAlertAction(title: "Voice only", style: .default) { _ in
            self.exportTake(clipsOnly: true)
        }
        let fullMix = UIAlertAction(title: "Full mix", style: .default) { _ in
            self.exportTake(clipsOnly: false)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        optionMenu.addAction(voiceOnly)
        optionMenu.addAction(fullMix)
        optionMenu.addAction(cancelAction)
        return optionMenu
    }

    private func getShareDialog() -> UIAlertController {
        let optionMenu = UIAlertController(title: nil, message: "Export Options", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        guard let takeID = state.takeID,
            let take = dependencies.realmService.getTake(id: takeID),
            let projectID = state.projectID,
            let project = dependencies.realmService.getProject(withID: projectID) else {
            return UIAlertController()
        }

        let shareAction = UIAlertAction(title: "Share", style: .default) { _ in
            self.shareTake(takeID: takeID)
        }
        let exportAction = UIAlertAction(title: "Export", style: .default) { _ in
            self.view?.presentView(view: self.getExportOptionDialog())
        }

        if project.isMyProject {
            optionMenu.addAction(exportAction)
        }
        if take.isMyTake {
            optionMenu.addAction(shareAction)
        }
        optionMenu.addAction(cancelAction)

        return optionMenu
    }

    private func addClips(_ clips: [AKFileClip]) {
        visualisationView?.clearVocalPlot {
            DispatchQueue.global().async {
                clips.forEach { clip in
                    guard let data = self.dependencies.recordHubAudioServiceService.getWaveformData(clip) else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.visualisationView?.addVocalPlot(duration: clip.audioFile.duration,
                                                             clipDuration: clip.duration,
                                                             time: clip.time,
                                                             offset: clip.offset,
                                                             data: data,
                                                             identifire: ObjectIdentifier(clip))
                    }
                }
            }
        }
    }
}

// MARK: - RecordHubAudioServiceServiceOutput

extension RecordHubPresenter: RecordHubAudioServiceServiceOutput {
    func sessionInterrupted() {
        state.isPlaying = false
        state.isRecording = false
        update(animated: true)
    }

    func sessionInterruptionEnded() {

    }

    func renderingProgress(progress: Double) {
        state.renderingProgress = progress
        update(animated: true)
    }

    func recordPlotReady(plot: AKNodeOutputPlot) {
        visualisationView?.addRecordPlot(plot: plot)
    }

    func sequenceCanUndo(_ can: Bool) {
        state.isUndoPossible = can
        update(animated: true)
    }

    func playerInitStarted() {
        state.isLoading = true
        update(animated: true)
    }

    func playerIsReady() {
        getWaveFormData()
        getWaveFormDataForFirstClip()
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

    func exportViewReady(view: UIViewController) {
        self.view?.presentView(view: view)
    }

    func recordStarted(position: Double) {
        visualisationView?.recordStarted(position: position)
    }

    func recordEnded() {
        visualisationView?.recordEnded()
    }

    func lastClipRemoved(_ clips: [AKFileClip]) {
        addClips(clips)
    }

    func filesRecorded(files: [AKFileClip]) {
        addClips(files)
    }
}

// MARK: - RecordHubViewOutput

extension RecordHubPresenter: RecordHubViewOutput {
    func backButtonPressed() {
        dependencies.recordHubAudioServiceService.stopRecord()
        dependencies.recordHubAudioServiceService.stopPlayback()
        guard state.hasChanges else {
            view?.exit()
            return
        }

        state.isRendering = true
        update(animated: true)
        dependencies.recordHubAudioServiceService.render(clipsOnly: true) { [weak self] url in
            guard let self = self else {
                return
            }
            self.state.isRendering = false
            self.state.isUploading = true
            self.update(animated: true)
            self.saveTake(withTemporaryAudioFileURL: url) { result in
                self.state.isUploading = false
                self.update(animated: true)
                switch result {
                case .success:
                    self.dependencies.recordHubAudioServiceService.stopRecordSession()
                    FileOperationManager.sharedInstance.cleanRecordsTmp()
                    self.dependencies.analyticsService.trackRecordingAdded(withProjectID: self.state.projectID ?? 0)
                    self.view?.exit()
                case let .failure(error):
                    self.view?.showError(error)
                }
            }
        }
    }

    func recordButtonPressed() {
        state.hasChanges = true
        let isRecording = dependencies.recordHubAudioServiceService.isRecording
        if !isRecording {
            state.isPlaying = true
            dependencies.recordHubAudioServiceService.setTime(position: state.currentTime ?? 0.0)
        }
        visualisationView?.blockScrolling(foo: !isRecording)
        state.isRecording = !isRecording
        dependencies.recordHubAudioServiceService.recordPressed()
        update(animated: true)
    }

    func undoPressed() {
        dependencies.recordHubAudioServiceService.undo()
    }

    func playButtonPressed() {
        let isPlaying = dependencies.recordHubAudioServiceService.isPlaying
        dependencies.recordHubAudioServiceService.setTime(position: state.currentTime ?? 0.0)
        state.isPlaying = !isPlaying
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

    func shareButtonPressed() {
        view?.presentView(view: getShareDialog())
    }

    func viewDidLoad() {
        update(animated: false)
        requestRecordPermission()
        chargeTake(project: state.projectID, takeID: state.takeID)
        dependencies.analyticsService.trackTakeAccessed(withTakeID: state.takeID ?? 0)
    }

    func vocalSliderValueChanged(value: Float) {
        setClipVolume(value)
    }

    func musicSliderValueChanged(value: Float) {
        setMusicVolume(value)
    }

    func viewWillDisapear() {
    }
}

// MARK: - RecordHubVisualisationViewOutput

extension RecordHubPresenter: RecordHubVisualisationViewOutput {
    var input: RecordHubVisualisationViewInput? {
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

    func frameForRecordingPlotSeted(frame: CGRect) {
        dependencies.recordHubAudioServiceService.setupPlot(for: frame)
    }
}

// MARK: - RecordHubModuleInput

extension RecordHubPresenter: RecordHubModuleInput {
    func update(animated: Bool) {
        let viewModel = RecordHubViewModel(state: state)
        view?.update(with: viewModel, animated: animated)
    }
}

// MARK: - Saving Takes

extension RecordHubPresenter {
    func saveTake(withTemporaryAudioFileURL fileURL: URL,
                  completion: @escaping (Result<Void, Error>) -> Void) {
        let temporaryMediaID = Int(Date().timeIntervalSinceReferenceDate)
        let result = FileOperationManager.sharedInstance.moveTemporaryFileToDocumentsDirectory(temporaryFileURL: fileURL,
                                                                                               mediaID: temporaryMediaID, subDirectoryName: "media")
        switch result {
        case let .failure(error):
            completion(.failure(error))
        case let .success(localFile):
            saveTake(with: localFile, completion: completion)
        }
    }

    private func saveTake(with localFile: LocalFile,
                          completion: @escaping (Result<Void, Error>) -> Void) {
        func updateTakeInOfflineMode() {
            do {
                let media = try makeUnsyncedMedia(for: localFile)
                updateTake(with: media) { result in
                    switch result {
                    case let .failure(error):
                        completion(.failure(error))
                    case .success:
                        completion(.success(()))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }

        func saveMediaAndUpdateLocalFile(media: Media, localFile: LocalFile) {
            dependencies.realmService.saveMediaAndUpdateLocalFile(media: media, localFile: localFile) { result in
                switch result {
                case let .failure(error):
                    completion(.failure(error))
                case .success:
                    // 3. Update take
                    self.updateTake(with: media) { result in
                        switch result {
                        case let .failure(error):
                            completion(.failure(error))
                        case .success:
                            completion(.success(()))
                        }
                    }
                }
            }
        }

        guard dependencies.reachabilityService.isReachable else {
            // Update take in offline mode
            updateTakeInOfflineMode()
            return
        }

        // Update take in online mode

        // 1. Upload new take audio file to the server
        uploadMedia(using: localFile, progressHandler: { [weak self] progress in
            guard let self = self else {
                return
            }
            self.state.uploadProgress = Double(progress)
            self.update(animated: true)
        }, completion: { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(media):
                // 2. Save uploaded media and update media id in local file
                saveMediaAndUpdateLocalFile(media: media, localFile: localFile)
            }
        })
    }

    private func makeUnsyncedMedia(for localFile: LocalFile) throws -> Media {
        return try RealmService.sharedInstance.newMedia(for: localFile)
    }

    private func updateTake(with media: Media, completion: @escaping (Result<Void, Error>) -> Void) {
        func updateTakeOnServer(take: Take) {
            if dependencies.reachabilityService.isReachable {
                var parameters: [String: Any] = ["lyrics": take.lyrics]
                if take.mediaID != 0 {
                    parameters["media_id"] = media.id
                }
                dependencies.apiService.updateTake(withID: take.id,
                                                   parameters: parameters,
                                                   completion: { result in
                                                       switch result {
                                                       case let .failure(error):
                                                           completion(.failure(error))
                                                       case .success:
                                                           completion(.success(()))
                                                       }
                })
            } else {
                completion(.success(()))
            }
        }

        guard let takeID = state.takeID,
            let take = dependencies.realmService.getTake(id: takeID) else {
            completion(.failure(TakeSavingError.invalidTake))
            return
        }

        // Update local take object
        dependencies.realmService.updateTake(take, media: media) { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case .success:
                // Take must exists on the backend
                guard !take.notSyncedCreate else {
                    self.dependencies.syncService.syncNewLocalObjects(completion: { _, _ in
                        // 7. Send take changes to the server if we can
                        updateTakeOnServer(take: take)

                    }, noInternet: {
                    })
                    return
                }
                // 7. Send take changes to the server if we can
                updateTakeOnServer(take: take)
            }
        }
    }

    private func uploadMedia(using localFile: LocalFile,
                             progressHandler: @escaping (Float) -> Void,
                             completion: @escaping (Result<Media, Error>) -> Void) {
        guard let filePath = localFile.localUrl else {
            completion(.failure(TakeSavingError.invalidMedia))
            return
        }

        let fullFilePath = Path.userDocuments + filePath
        guard fullFilePath.exists else {
            completion(.failure(TakeSavingError.invalidMedia))
            return
        }

        let mediaSource = MediaSource.fileURL(fullFilePath.url)
        Api.sharedInstance.uploadMedia(using: mediaSource, progressHandler: { progress in
            progressHandler(Float(progress.fractionCompleted))
        }, completion: completion)
    }
}

private enum TakeSavingError: Equatable {
    case invalidProject
    case invalidTake
    case invalidMedia
    case downloadProblem
    case invalidTakeID
}

extension TakeSavingError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidProject:
            return "Project is invalid."
        case .invalidTake:
            return "Take is invalid."
        case .invalidMedia:
            return "Media is invalid."
        case .downloadProblem:
            return "Problems with file download. Try again later."
        case .invalidTakeID:
            return "Invalid take id"
        }
    }
}
