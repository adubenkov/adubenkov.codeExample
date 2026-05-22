//
//  Created by Andrey Dubenkov on 10/11/2019
//  Copyright © 2019 . All rights reserved.
//

final class ProjectHubState {
    var projectID: Int?
    var isLoading: Bool = false
    var isPlaying: Bool = false
    var isMyProject: Bool = false
    var wasPlayed: Bool = false
    var isScrubbing: Bool = false
    var isVolumePanelOpen: Bool = false
    var currentTime: Double?
    var scenario: ProjectHubScenario?

    init(projectID: Int, scenario: ProjectHubScenario) {
        self.projectID = projectID
        self.scenario = scenario
    }
}
