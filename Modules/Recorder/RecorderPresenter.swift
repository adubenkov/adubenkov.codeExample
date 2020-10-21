//
//  Created by Andrey Dubenkov on 01/04/2020
//  Copyright © 2020 . All rights reserved.
//

import AudioKit
import AudioKitUI
import AVFoundation

final class RecorderPresenter {
    typealias Dependencies = HasRecordHubAudioServiceService

    weak var view: RecorderViewInput?
    weak var plotView: RecorderPlotViewInput?
    weak var output: RecorderModuleOutput?

    var state: RecorderState

    private let dependencies: Dependencies

    init(state: RecorderState,
         dependencies: Dependencies) {
        self.state = state
        self.dependencies = dependencies
    }

    // MARK: - Private

    private func requestRecordPermission() {
        let audioSession = AVAudioSession.sharedInstance()
        audioSession.requestRecordPermission { isAccessGranted in
            print("AVAudioSession - requested record permission for audio session:")
            print(isAccessGranted ? "Record access granted" : "Record access denied")
        }
    }

    private func startRecorder() {
        dependencies.recordHubAudioServiceService.output = self
        dependencies.recordHubAudioServiceService.startRecordingSession(withProjectTrackFile: nil, takeFile: nil)
    }

    private func addClips(_ clips: [AKFileClip]) {
        plotView?.clearVocalPlot {
            DispatchQueue.global().async {
                clips.forEach { clip in
                    guard let data = self.dependencies.recordHubAudioServiceService.getWaveformData(clip) else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.plotView?.addVocalPlot(duration: clip.audioFile.duration,
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

// MARK: - RecorderPlotViewOutput

extension RecorderPresenter: RecorderPlotViewOutput {
    var input: RecorderPlotViewInput? {
        get {
            return plotView
        }
        set {
            plotView = newValue
        }
    }

    func frameForRecordingPlotSeted(frame: CGRect) {
        dependencies.recordHubAudioServiceService.setupPlot(for: frame)
    }

    func scrollViewWillBeginDragging() {
        state.isScrubbing = true
    }

    func scrollViewWillEndDragging() {
        if dependencies.recordHubAudioServiceService.isPlaying {
            state.wasPlayed = true
        }
    }

    func scrollViewDidScrollToOffset(position: Double) {
        state.currentTime = position
        update(animated: true)
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

// MARK: - RecordHubAudioServiceServiceOutput

extension RecorderPresenter: RecordHubAudioServiceServiceOutput {
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
        plotView?.addRecordPlot(plot: plot)
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
        view?.exit()
    }

    func playheadPosition(position: Double) {
        if !state.isScrubbing {
            state.currentTime = position
            update(animated: true)
            plotView?.movePlayhead(position)
        }
    }

    func fileEnded() {
        state.isPlaying = false
        update(animated: true)
    }

    func exportViewReady(view: UIViewController) {
    }

    func recordStarted(position: Double) {
        plotView?.recordStarted(position: position)
    }

    func recordEnded() {
        plotView?.recordEnded()
    }

    func lastClipRemoved(_ clips: [AKFileClip]) {
        addClips(clips)
    }

    func filesRecorded(files: [AKFileClip]) {
        addClips(files)
    }
}

// MARK: - RecorderViewOutput

extension RecorderPresenter: RecorderViewOutput {
    func recordButtonPressed() {
        state.hasChanges = true
        let isRecording = dependencies.recordHubAudioServiceService.isRecording
        if !isRecording {
            state.isPlaying = true
            dependencies.recordHubAudioServiceService.setTime(position: state.currentTime)
        }
        state.isRecording = !isRecording
        plotView?.isRecording = !isRecording
        dependencies.recordHubAudioServiceService.recordPressed()
        update(animated: true)
    }

    func undoButtonPressed() {
        dependencies.recordHubAudioServiceService.undo()
    }

    func rewindButtonPressed() {
        dependencies.recordHubAudioServiceService.rewind()
    }

    func playButtonPressed() {
        let isPlaying = dependencies.recordHubAudioServiceService.isPlaying
        dependencies.recordHubAudioServiceService.setTime(position: state.currentTime)
        state.isPlaying = !isPlaying
        dependencies.recordHubAudioServiceService.playPressed()
        update(animated: true)
    }

    func saveButtonPressed() {
        dependencies.recordHubAudioServiceService.stopRecord()
        dependencies.recordHubAudioServiceService.stopPlayback()
        guard state.hasChanges else {
            output?.recorderModuleDidClose(self)
            return
        }

        state.isRendering = true
        update(animated: true)
        dependencies.recordHubAudioServiceService.render(clipsOnly: true) { [weak self] url in
            guard let self = self else {
                return
            }
            self.state.isRendering = false
            self.update(animated: true)
            self.output?.fileIsReady(url)
        }
    }

    func viewDidLoad() {
        update(animated: false)
        requestRecordPermission()
        startRecorder()
    }
}

// MARK: - RecorderModuleInput

extension RecorderPresenter: RecorderModuleInput {
    func update(animated: Bool) {
        let viewModel = RecorderViewModel(state: state)
        view?.update(with: viewModel, animated: animated)
    }
}
