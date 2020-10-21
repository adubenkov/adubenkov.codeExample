//
//  Created by Andrey Dubenkov on 10/11/2019
//  Copyright © 2019 . All rights reserved.
//

struct ProjectHubViewModel: Equatable {
    var projectID: Int?

    var isPlaying: Bool = false
    var isLoading: Bool = false
    var isVolumePanelOpen: Bool = false
    var isMyProject: Bool = false
    var currentTimeString: String = "00:00.00"
    var scenario: ProjectHubScenario?

    init(state: ProjectHubState) {
        isLoading = state.isLoading
        isVolumePanelOpen = state.isVolumePanelOpen
        projectID = state.projectID
        isPlaying = state.isPlaying
        currentTimeString = ProjectHubViewModel.timeStringFrom(position: state.currentTime)
        scenario = state.scenario
        isMyProject = state.isMyProject
    }

    static func == (lhs: ProjectHubViewModel, rhs: ProjectHubViewModel) -> Bool {
        return lhs.isLoading == rhs.isLoading &&
            lhs.isVolumePanelOpen == rhs.isVolumePanelOpen &&
            lhs.projectID == rhs.projectID &&
            lhs.isPlaying == rhs.isPlaying &&
            lhs.scenario == rhs.scenario &&
            lhs.currentTimeString == rhs.currentTimeString &&
            lhs.isMyProject == rhs.isMyProject
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
