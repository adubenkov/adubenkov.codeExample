import Foundation

enum UserPolicyKey: String {
    case customLayout
    case advancedAnalysis
    case feedItemLimit
    case topicLimit
    case savedItems
    case referralProgram
    case featurePreview
}

enum UserPolicyValueType: String {
    case binary
    case limit
    case both
}

struct UserPolicy {
    let id: String
    let type: UserPolicyValueType
    let enabled: Bool
    let limit: Int?
    let name: String?
    let description: String?
}

struct RemoteUserPolicy: Codable {
    let id: String?
    let type: String?
    let enabled: Bool?
    let limit: Int?
    let name: String?
    let description: String?
}

struct RemoteUserPoliciesResponse: Codable {
    let policies: [RemoteUserPolicy]?
}
