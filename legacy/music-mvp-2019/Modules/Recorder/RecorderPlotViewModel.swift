//
//  RecorderPlotViewModel.swift
//  
//
//  Created by Andrey Dubenkov on 05.04.2020.
//  Copyright © 2020 . All rights reserved.
//

import Foundation
struct RecorderPlotViewModel: Equatable {
    var isScrolingEnabled: Bool = false
    var isRecording: Bool = false
    var position: Double = 0.0

    init(state: RecorderPlotState) {
        isRecording = state.isRecording
        isScrolingEnabled = state.isScrolingEnabled
        position = state.position
    }

    static func == (lhs: RecorderPlotViewModel, rhs: RecorderPlotViewModel) -> Bool {
        return
            lhs.isScrolingEnabled == rhs.isScrolingEnabled &&
            lhs.isRecording == rhs.isRecording &&
            lhs.position == rhs.position
    }
}
