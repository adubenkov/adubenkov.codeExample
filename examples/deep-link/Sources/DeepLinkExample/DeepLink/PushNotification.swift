import Foundation

struct PushNotification {
    enum Action: String {
        case url = "openUrl"
        case event = "openEvent"
    }

    let action: Action
    let url: String?
    let eventID: String?

    init?(userInfo: [AnyHashable: Any]) {
        guard
            let actionString = userInfo["action"] as? String,
            let action = Action(rawValue: actionString)
        else {
            return nil
        }
        self.action = action
        self.url = userInfo["url"] as? String
        self.eventID = userInfo["eventId"] as? String
    }
}
