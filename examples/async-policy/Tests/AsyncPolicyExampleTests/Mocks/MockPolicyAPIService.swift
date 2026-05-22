import Foundation

@testable import AsyncPolicyExample

final class MockPolicyAPIService: PolicyAPIService {
    enum APIError: Error {
        case http
    }

    var mockGetUserPoliciesResult: RemoteUserPoliciesResponse?
    var mockGetUserPoliciesError: Error?

    func getUserPolicies() async throws -> RemoteUserPoliciesResponse {
        if let mockGetUserPoliciesError {
            throw mockGetUserPoliciesError
        }
        return mockGetUserPoliciesResult ?? RemoteUserPoliciesResponse(policies: nil)
    }
}
