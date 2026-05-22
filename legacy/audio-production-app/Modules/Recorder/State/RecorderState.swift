//
//  Created by Andrey Dubenkov on 01/04/2020
//  Copyright © 2020 . All rights reserved.
//

final class RecorderState {
    var isLoading: Bool = false
    var isPlaying: Bool = false
    var isUndoPossible: Bool = false
    var wasPlayed: Bool = false
    var isScrubbing: Bool = false
    var isRecording: Bool = false
    var currentTime: Double = 0.0
    var isRendering: Bool = false
    var renderingProgress: Double = 0.0
    var hasChanges: Bool = false
}
