import Foundation

struct FeatureFlagTrialScreenHeader: Codable {
    let title: String
}

struct FeatureFlagTrialScreenReview: Codable {
    let numberOfReviews: String
    let averageRating: String
}

struct FeatureFlagTrialScreenFeature: Codable {
    let id: String
    let icon: URL
    let title: String
}

struct FeatureFlagTrialScreen: Codable {
    let product: String
    let cohort: String
    let paywallCampaign: String?
    let header: FeatureFlagTrialScreenHeader
    let features: [FeatureFlagTrialScreenFeature]
    let review: FeatureFlagTrialScreenReview

    enum CodingKeys: String, CodingKey {
        case product
        case cohort
        case paywallCampaign = "superwallCampaign"
        case header
        case features
        case review
    }

    func toData() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try? encoder.encode(self)
    }
}

struct FeatureFlagTrialScreenList: Codable {
    let screens: [FeatureFlagTrialScreen]

    static func from(_ data: Data) -> FeatureFlagTrialScreenList? {
        if let screens = try? JSONDecoder().decode([FeatureFlagTrialScreen].self, from: data) {
            return FeatureFlagTrialScreenList(screens: screens)
        }
        return try? JSONDecoder().decode(FeatureFlagTrialScreenList.self, from: data)
    }
}

struct FeatureFlagPricingExperimentData: Codable {
    let paywallCampaign: String?
    let cohort: String
    let productIdentifiers: [String]

    enum CodingKeys: String, CodingKey {
        case paywallCampaign = "superwallCampaign"
        case cohort
        case productIdentifiers
    }
}

struct FeatureFlagPricingExperimentDataList: Codable {
    let data: [FeatureFlagPricingExperimentData]

    static func from(_ data: Data) -> FeatureFlagPricingExperimentDataList? {
        if let items = try? JSONDecoder().decode([FeatureFlagPricingExperimentData].self, from: data) {
            return FeatureFlagPricingExperimentDataList(data: items)
        }
        return try? JSONDecoder().decode(FeatureFlagPricingExperimentDataList.self, from: data)
    }

    static func experiment(fromJSONObject pricingExperimentData: [[String: Any]], cohort: String) -> FeatureFlagPricingExperimentData? {
        guard
            let data = try? JSONSerialization.data(withJSONObject: pricingExperimentData, options: [.fragmentsAllowed, .sortedKeys]),
            let model = FeatureFlagPricingExperimentDataList.from(data) else {
            return nil
        }
        return model.data.first(where: { $0.cohort == cohort })
    }
}
