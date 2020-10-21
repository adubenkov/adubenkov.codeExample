//
//  Created by Andrey Dubenkov on 01/04/2020
//  Copyright © 2020 . All rights reserved.
//

struct RecorderViewModel: Equatable {
    var currentTimeString: String = "00:00.00"
    var isPlaying: Bool = false
    var isRecording: Bool = false
    var isLoading: Bool = false
    var isRendering: Bool = false
    var renderingProgress: Double = 0.0
    var isUndoPossible: Bool = false

    init(state: RecorderState) {
        currentTimeString = RecorderViewModel.timeStringFrom(position: state.currentTime)
        isPlaying = state.isPlaying
        isRecording = state.isRecording
        isLoading = state.isLoading
        isRendering = state.isRendering
        renderingProgress = state.renderingProgress
        isUndoPossible = state.isUndoPossible
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
        case 0 ... 9:
            msStr = "0\(mSeconds)"
        case 10 ... 99:
            msStr = "\(mSeconds)"
        default:
            msStr = "\(mSeconds)"
        }
        return "\(minStr):\(secStr).\(msStr)"
    }

    static func == (lhs: RecorderViewModel, rhs: RecorderViewModel) -> Bool {
        return
            lhs.currentTimeString == rhs.currentTimeString &&
            lhs.isPlaying == rhs.isPlaying &&
            lhs.isRecording == rhs.isRecording &&
            lhs.isLoading == rhs.isLoading &&
            lhs.isRendering == rhs.isRendering &&
            lhs.renderingProgress == rhs.renderingProgress &&
            lhs.isUndoPossible == rhs.isUndoPossible &&
            lhs.isPlaying == rhs.isPlaying &&
            lhs.isPlaying == rhs.isPlaying
    }
}
