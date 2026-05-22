import XCTest

@testable import AsyncPolicyExample

final class AppUserPolicyServiceTests: XCTestCase {
    private var service: AppUserPolicyService!
    private var mockPolicyAPIService: MockPolicyAPIService!

    override func setUp() {
        super.setUp()
        mockPolicyAPIService = MockPolicyAPIService()
        service = AppUserPolicyService(policyAPIService: mockPolicyAPIService)
    }

    override func tearDown() {
        service = nil
        mockPolicyAPIService = nil
        super.tearDown()
    }

    private func createRemotePolicy(id: String, type: String?, enabled: Bool?, limit: Int? = nil) -> RemoteUserPolicy {
        return RemoteUserPolicy(id: id, type: type, enabled: enabled, limit: limit, name: "Test Policy", description: "Test Description")
    }
}

extension AppUserPolicyServiceTests {
    func testConfigureCallsAPIAndHandlesSuccess() async throws {
        let policy = createRemotePolicy(id: "customLayout", type: "binary", enabled: true, limit: nil)
        mockPolicyAPIService.mockGetUserPoliciesResult = RemoteUserPoliciesResponse(policies: [policy])
        let userPolicyBeforeConfiguring = service.isEnabled(.customLayout)

        try await service.configure()

        XCTAssertFalse(userPolicyBeforeConfiguring)
        XCTAssertTrue(service.isEnabled(.customLayout))
    }

    func testConfigureHandlesAPIError() async {
        mockPolicyAPIService.mockGetUserPoliciesError = MockPolicyAPIService.APIError.http

        do {
            try await service.configure()
            XCTFail("Expected error to be thrown")
        } catch {
            guard case MockPolicyAPIService.APIError.http = error else {
                return XCTFail("Expected .http")
            }
        }
    }
}

extension AppUserPolicyServiceTests {
    func testBinaryPolicyEnabled() async throws {
        let policy = createRemotePolicy(id: "customLayout", type: "binary", enabled: true, limit: nil)
        mockPolicyAPIService.mockGetUserPoliciesResult = RemoteUserPoliciesResponse(policies: [policy])

        try await service.configure()

        XCTAssertTrue(service.isEnabled(.customLayout))
        XCTAssertFalse(service.isUnlimited(.customLayout))
        XCTAssertNil(service.limitFor(.customLayout))
    }

    func testLimitPolicyWithLimit() async throws {
        let policy = createRemotePolicy(id: "feedItemLimit", type: "limit", enabled: nil, limit: 5)
        mockPolicyAPIService.mockGetUserPoliciesResult = RemoteUserPoliciesResponse(policies: [policy])

        try await service.configure()

        XCTAssertTrue(service.isEnabled(.feedItemLimit))
        XCTAssertFalse(service.isUnlimited(.feedItemLimit))
        XCTAssertEqual(service.limitFor(.feedItemLimit), 5)
    }

    func testLimitPolicyUnlimited() async throws {
        let policy = createRemotePolicy(id: "feedItemLimit", type: "limit", enabled: nil, limit: -1)
        mockPolicyAPIService.mockGetUserPoliciesResult = RemoteUserPoliciesResponse(policies: [policy])

        try await service.configure()

        XCTAssertTrue(service.isEnabled(.feedItemLimit))
        XCTAssertTrue(service.isUnlimited(.feedItemLimit))
        XCTAssertEqual(service.limitFor(.feedItemLimit), -1)
    }

    func testBothPolicyEnabledWithLimit() async throws {
        let policy = createRemotePolicy(id: "topicLimit", type: "both", enabled: true, limit: 10)
        mockPolicyAPIService.mockGetUserPoliciesResult = RemoteUserPoliciesResponse(policies: [policy])

        try await service.configure()

        XCTAssertTrue(service.isEnabled(.topicLimit))
        XCTAssertFalse(service.isUnlimited(.topicLimit))
        XCTAssertEqual(service.limitFor(.topicLimit), 10)
    }

    func testBothPolicyDisabledUnlimited() async throws {
        let policy = createRemotePolicy(id: "topicLimit", type: "both", enabled: false, limit: -1)
        mockPolicyAPIService.mockGetUserPoliciesResult = RemoteUserPoliciesResponse(policies: [policy])

        try await service.configure()

        XCTAssertFalse(service.isEnabled(.topicLimit))
        XCTAssertTrue(service.isUnlimited(.topicLimit))
        XCTAssertEqual(service.limitFor(.topicLimit), -1)
    }
}

extension AppUserPolicyServiceTests {
    func testUnknownPolicyBehavior() async throws {
        mockPolicyAPIService.mockGetUserPoliciesResult = RemoteUserPoliciesResponse(policies: [])

        try await service.configure()

        XCTAssertFalse(service.isEnabled(.advancedAnalysis))
        XCTAssertFalse(service.isUnlimited(.advancedAnalysis))
        XCTAssertNil(service.limitFor(.advancedAnalysis))
    }

    func testCreatePolicyWithInvalidData() async throws {
        let invalidIdPolicy = createRemotePolicy(id: "invalidPolicyId", type: "binary", enabled: true)
        let invalidTypePolicy = createRemotePolicy(id: "customLayout", type: "invalidType", enabled: true)
        mockPolicyAPIService.mockGetUserPoliciesResult = RemoteUserPoliciesResponse(policies: [invalidIdPolicy, invalidTypePolicy])

        try await service.configure()

        XCTAssertFalse(service.isEnabled(.customLayout))
    }

    func testConfigureWithNilPolicies() async throws {
        mockPolicyAPIService.mockGetUserPoliciesResult = RemoteUserPoliciesResponse(policies: nil)

        try await service.configure()

        XCTAssertFalse(service.isEnabled(.customLayout))
        XCTAssertFalse(service.isEnabled(.feedItemLimit))
    }
}
