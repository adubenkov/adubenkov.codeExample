//
//  Created by Andrey Dubenkov on 13/11/2019
//  Copyright © 2019 . All rights reserved.
//

final class RecordHubState {
    var projectID: Int?
    var takeID: Int?
    var isLoading: Bool = false
    var isVolumePanelOpen: Bool = false
    var isPlaying: Bool = false
    var isUndoPossible: Bool = false
    var wasPlayed: Bool = false
    var isScrubbing: Bool = false
    var isRecording: Bool = false
    var currentTime: Double?
    var isUploading: Bool = false
    var uploadProgress: Double?
    var isRendering: Bool = false
    var renderingProgress: Double?
    var hasChanges: Bool = false
    var isMyTake: Bool = false
    init(projectID: Int, takeID: Int) {
        self.projectID = projectID
        self.takeID = takeID
    }

}
