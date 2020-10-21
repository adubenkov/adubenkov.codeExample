//
//  Created by Andrey Dubenkov on 13/11/2019
//  Copyright © 2019 . All rights reserved.
//

struct RecordHubViewModel: Equatable {
    var projectID: Int?
    var takeID: Int?

    var isPlaying: Bool = false
    var isRecording: Bool = false
    var isLoading: Bool = false
    var isRendering: Bool = false
    var isUploading: Bool = false
    var uploadProgress: Double = 0.0
    var renderingProgress: Double = 0.0
    var isUndoPossible: Bool = false
    var isVolumePanelOpen: Bool = false
    var currentTimeString: String = "00:00.00"
    var isMyTake: Bool = false

    init(state: RecordHubState) {
        isLoading = state.isLoading
        isVolumePanelOpen = state.isVolumePanelOpen
        projectID = state.projectID
        takeID = state.takeID
        isPlaying = state.isPlaying
        isRecording = state.isRecording
        isUndoPossible = state.isUndoPossible
        isRendering = state.isRendering
        isUploading = state.isUploading
        uploadProgress = state.uploadProgress ?? 0.0
        renderingProgress = state.renderingProgress ?? 0.0
        currentTimeString = RecordHubViewModel.timeStringFrom(position: state.currentTime)
        isMyTake = state.isMyTake
    }

    static func == (lhs: RecordHubViewModel, rhs: RecordHubViewModel) -> Bool {
        return lhs.isLoading == rhs.isLoading &&
            lhs.isVolumePanelOpen == rhs.isVolumePanelOpen &&
            lhs.projectID == rhs.projectID &&
            lhs.takeID == rhs.takeID &&
            lhs.isPlaying == rhs.isPlaying &&
            lhs.isRecording == rhs.isRecording &&
            lhs.isUndoPossible == rhs.isUndoPossible &&
            lhs.isRecording == rhs.isRecording &&
            lhs.isUploading == rhs.isUploading &&
            lhs.uploadProgress == rhs.uploadProgress &&
            lhs.renderingProgress == rhs.renderingProgress &&
            lhs.isMyTake == rhs.isMyTake &&
            lhs.currentTimeString == rhs.currentTimeString
    }

    static func timeStringFrom(position: Double?) -> String {
        guard let position = position else {
            return "00:00.00"
        }
        let currentTime = position
        let minutes = Int(currentTime / 60)
        let minStr = minutes < 10 ? "0\(minutes)" : "\(minutes)"
        let seconds = Int(currentTime - Double(minutes) * 60)
        let secStr = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        let mSeconds = Int((currentTime - Double(minutes) * 60 - Double(seconds)) * 100)
        var msStr = ""
        switch mSeconds {
        case 0...9:
            msStr = "0\(mSeconds)"
        case 10...99:
            msStr = "\(mSeconds)"
        default:
            msStr = "\(mSeconds)"
        }
        return "\(minStr):\(secStr).\(msStr)"
    }
}
