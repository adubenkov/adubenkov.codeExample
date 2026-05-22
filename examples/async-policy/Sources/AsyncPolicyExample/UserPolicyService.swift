import Foundation

protocol PolicyAPIService: AnyObject {
    func getUserPolicies() async throws -> RemoteUserPoliciesResponse
}

protocol UserPolicyService: AnyObject {
    func configure() async throws
    func isEnabled(_ userPolicy: UserPolicyKey) -> Bool
    func limitFor(_ userPolicy: UserPolicyKey) -> Int?
    func isUnlimited(_ userPolicy: UserPolicyKey) -> Bool
}
