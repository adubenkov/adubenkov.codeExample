import Foundation

enum TrialState: Equatable {
    case introductoryOffer
    case promotionalOffer(offer: PromotionalOfferDiscount)
    case paywallCampaign(campaign: String)

    init?(userHasActiveSubscription: Bool,
          isInstitutionLogin: Bool,
          isEligibleForIntroOffer: Bool?,
          remoteConfigurationValue: RemoteConfigurationValue?,
          isVantageVisibilityPolicyEnabled: Bool,
          promotionalOffers: [PromotionalOfferDiscount],
          showNewTrialScreen: Bool,
          trialScreenData: [[String: Any]],
          paywallCampaign: String,
          pricingExperimentData: [[String: Any]]) {
        if let state = TrialState.from(userHasActiveSubscription: userHasActiveSubscription,
                                       isInstitutionLogin: isInstitutionLogin,
                                       isEligibleForIntroOffer: isEligibleForIntroOffer,
                                       remoteConfigurationValue: remoteConfigurationValue,
                                       isVantageVisibilityPolicyEnabled: isVantageVisibilityPolicyEnabled,
                                       promotionalOffers: promotionalOffers,
                                       showNewTrialScreen: showNewTrialScreen,
                                       trialScreenData: trialScreenData,
                                       paywallCampaign: paywallCampaign,
                                       pricingExperimentData: pricingExperimentData) {
            self = state
        } else {
            return nil
        }
    }

    private static func from(userHasActiveSubscription: Bool,
                             isInstitutionLogin: Bool,
                             isEligibleForIntroOffer: Bool?,
                             remoteConfigurationValue: RemoteConfigurationValue?,
                             isVantageVisibilityPolicyEnabled: Bool,
                             promotionalOffers: [PromotionalOfferDiscount],
                             showNewTrialScreen: Bool,
                             trialScreenData: [[String: Any]],
                             paywallCampaign: String,
                             pricingExperimentData: [[String: Any]]) -> TrialState? {
        if userHasActiveSubscription || isInstitutionLogin {
            return nil
        }

        guard let isEligibleForIntroOffer else {
            return nil
        }

        let trialScreenRemoteConfig = trialScreenRemoteConfig(isVantageVisibilityPolicyEnabled: isVantageVisibilityPolicyEnabled, remoteConfigurationValue: remoteConfigurationValue)
        if isEligibleForIntroOffer {
            return introductoryOfferState(showNewTrialScreen: showNewTrialScreen, trialScreenRemoteConfig: trialScreenRemoteConfig, trialScreenData: trialScreenData, paywallCampaign: paywallCampaign, pricingExperimentData: pricingExperimentData)
        }

        if let promotionalOffer = promotionalOffer(trialScreenRemoteConfig: trialScreenRemoteConfig, promotionalOffers: promotionalOffers) {
            return .promotionalOffer(offer: promotionalOffer)
        }

        return nil
    }

    private static func trialScreenRemoteConfig(isVantageVisibilityPolicyEnabled: Bool, remoteConfigurationValue: RemoteConfigurationValue?) -> TrialScreenRemoteConfig {
        guard case let .trialScreenPremiumVantage(configuration) = remoteConfigurationValue, let configuration else {
            return .premium
        }

        let configurationIsVantage = switch configuration {
        case .vantage, .vantageUS7199, .vantageControl, .vantageUS7199Control: true
        case .premium, .premiumUS3999, .premiumUS4999, .premiumUS4499, .premiumUS3999Control, .premiumControl, .premiumUS4499Control, .premiumUS4999Control: false
        }

        guard isVantageVisibilityPolicyEnabled else {
            return configurationIsVantage ? .premium : configuration
        }

        return configuration
    }

    private static func promotionalOffer(trialScreenRemoteConfig: TrialScreenRemoteConfig, promotionalOffers: [PromotionalOfferDiscount]) -> PromotionalOfferDiscount? {
        let eligiblePromotionalOffers = promotionalOffers.filter { $0.id.contains(FreeTrialConstants.oneWeekFreeTrial) }

        if eligiblePromotionalOffers.isEmpty {
            return nil
        }

        switch trialScreenRemoteConfig {
        case .premium, .premiumControl: return eligiblePromotionalOffers.first(where: { $0.subscriptionPlan == .premium })
        case .vantage, .vantageControl: return eligiblePromotionalOffers.first(where: { $0.subscriptionPlan == .vantage })
        case .vantageUS7199, .vantageUS7199Control: return eligiblePromotionalOffers.first(where: { $0.subscriptionType == .yearlyVantageUS7199 })
        case .premiumUS3999, .premiumUS3999Control: return eligiblePromotionalOffers.first(where: { $0.subscriptionType == .yearlyPremiumUS3999 })
        case .premiumUS4499, .premiumUS4499Control: return eligiblePromotionalOffers.first(where: { $0.subscriptionType == .yearlyPremiumUS4499 })
        case .premiumUS4999, .premiumUS4999Control: return eligiblePromotionalOffers.first(where: { $0.subscriptionType == .yearlyPremiumUS4999 })
        }
    }

    private static func forceOldExperimentUsersToSeePaywall(showNewTrialScreen: Bool, trialScreenRemoteConfig: TrialScreenRemoteConfig, trialScreenData: [[String: Any]]) -> String? {
        guard showNewTrialScreen else {
            return nil
        }
        guard let screen = trialScreen(trialScreenRemoteConfig: trialScreenRemoteConfig, trialScreenData: trialScreenData) else {
            return nil
        }
        guard let campaign = screen.paywallCampaign, !campaign.isEmptyOrWhitespace else {
            return nil
        }
        return campaign
    }

    private static func introductoryOfferState(showNewTrialScreen: Bool, trialScreenRemoteConfig: TrialScreenRemoteConfig, trialScreenData: [[String: Any]], paywallCampaign: String, pricingExperimentData: [[String: Any]]) -> TrialState {
        if let experimentCampaign = forceOldExperimentUsersToSeePaywall(showNewTrialScreen: showNewTrialScreen, trialScreenRemoteConfig: trialScreenRemoteConfig, trialScreenData: trialScreenData) {
            return .paywallCampaign(campaign: experimentCampaign)
        }

        if let pricingExperiment = pricingExperiment(pricingExperimentData: pricingExperimentData, trialScreenPremiumVantage: trialScreenRemoteConfig), let experimentCampaign = pricingExperiment.paywallCampaign, !experimentCampaign.isEmptyOrWhitespace {
            return .paywallCampaign(campaign: experimentCampaign)
        }

        if !paywallCampaign.isEmptyOrWhitespace {
            return .paywallCampaign(campaign: paywallCampaign)
        }

        return .introductoryOffer
    }
}

extension TrialState {
    private static func trialScreen(trialScreenRemoteConfig: TrialScreenRemoteConfig, trialScreenData: [[String: Any]]) -> FeatureFlagTrialScreen? {
        guard
            let data = try? JSONSerialization.data(withJSONObject: trialScreenData, options: [.fragmentsAllowed, .sortedKeys]),
            let list = FeatureFlagTrialScreenList.from(data) else {
            return nil
        }
        let product = switch trialScreenRemoteConfig {
        case .premium, .vantage: trialScreenRemoteConfig.rawValue
        case .vantageUS7199, .vantageControl, .vantageUS7199Control: TrialScreenRemoteConfig.vantage.rawValue
        case .premiumUS3999, .premiumUS4999, .premiumUS4499, .premiumUS3999Control, .premiumControl, .premiumUS4499Control, .premiumUS4999Control: TrialScreenRemoteConfig.premium.rawValue
        }
        return list.screens.first(where: { $0.product == product })
    }

    private static func pricingExperiment(pricingExperimentData: [[String: Any]], trialScreenPremiumVantage: TrialScreenRemoteConfig) -> FeatureFlagPricingExperimentData? {
        return FeatureFlagPricingExperimentDataList.experiment(fromJSONObject: pricingExperimentData, cohort: trialScreenPremiumVantage.rawValue)
    }
}
