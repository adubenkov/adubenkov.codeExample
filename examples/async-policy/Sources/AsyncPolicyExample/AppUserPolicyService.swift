import Foundation

final class AppUserPolicyService: UserPolicyService {
    private let policyAPIService: PolicyAPIService
    private var userPolicies: [UserPolicyKey: UserPolicy] = [:]

    init(policyAPIService: PolicyAPIService) {
        self.policyAPIService = policyAPIService
    }

    func configure() async throws {
        let response = try await policyAPIService.getUserPolicies()
        userPolicies = createPolicies(from: response.policies ?? [])
    }

    private func createPolicies(from remotePolicies: [RemoteUserPolicy]) -> [UserPolicyKey: UserPolicy] {
        return Dictionary(uniqueKeysWithValues: remotePolicies.compactMap { remotePolicy in
            createPolicy(from: remotePolicy)
        })
    }

    private func createPolicy(from remotePolicy: RemoteUserPolicy) -> (UserPolicyKey, UserPolicy)? {
        guard let policyId = remotePolicy.id,
              let key = UserPolicyKey(rawValue: policyId),
              let policyType = remotePolicy.type,
              let valueType = UserPolicyValueType(rawValue: policyType),
              let enabled = enabledValue(for: valueType, from: remotePolicy) else {
            return nil
        }

        return (
            key,
            UserPolicy(
                id: policyId,
                type: valueType,
                enabled: enabled,
                limit: remotePolicy.limit,
                name: remotePolicy.name,
                description: remotePolicy.description
            )
        )
    }

    private func enabledValue(for type: UserPolicyValueType, from policy: RemoteUserPolicy) -> Bool? {
        switch type {
        case .limit: return true
        case .binary, .both: return policy.enabled
        }
    }

    func isEnabled(_ userPolicy: UserPolicyKey) -> Bool {
        return userPolicies[userPolicy]?.enabled ?? false
    }

    func limitFor(_ userPolicy: UserPolicyKey) -> Int? {
        return userPolicies[userPolicy]?.limit
    }

    func isUnlimited(_ userPolicy: UserPolicyKey) -> Bool {
        guard let policy = userPolicies[userPolicy],
              let limit = policy.limit else {
            return false
        }
        return limit == -1
    }
}
