import XCTest

@testable import SubscriptionStateExample

final class TrialStateTests: XCTestCase {
    private let premiumFreeTrialPromotionalOffer = PromotionalOfferDiscount(
        id: "com.example.app.yearly.premium.1weekfreetrial",
        name: "Premium",
        discountPrice: 0,
        localizedDiscountPriceString: "$0",
        originalPrice: 9.99,
        localizedOriginalPriceString: "$9.99",
        currencyCode: "USD",
        numberOfPeriods: 1,
        periodLength: .week,
        subscriptionType: .yearlyPremium,
        subscriptionPlan: .premium,
        productIdentifier: "com.example.app.yearly.premium"
    )
    private let vantageFreeTrialPromotionalOffer = PromotionalOfferDiscount(
        id: "com.example.app.yearly.vantage.1weekfreetrial",
        name: "Vantage",
        discountPrice: 0,
        localizedDiscountPriceString: "$0",
        originalPrice: 12.99,
        localizedOriginalPriceString: "$12.99",
        currencyCode: "USD",
        numberOfPeriods: 1,
        periodLength: .week,
        subscriptionType: .yearlyVantage,
        subscriptionPlan: .vantage,
        productIdentifier: "com.example.app.yearly.vantage"
    )
    private let premiumPromotionalOffer = PromotionalOfferDiscount(
        id: "com.example.app.yearly.premium.40off",
        name: "Premium",
        discountPrice: 0,
        localizedDiscountPriceString: "$0",
        originalPrice: 9.99,
        localizedOriginalPriceString: "$9.99",
        currencyCode: "USD",
        numberOfPeriods: 1,
        periodLength: .week,
        subscriptionType: .yearlyPremium,
        subscriptionPlan: .premium,
        productIdentifier: "com.example.app.yearly.premium"
    )
    private let vantageUS7199FreeTrialPromotionalOffer = PromotionalOfferDiscount(
        id: "com.example.app.yearly.vantage.us7199.1weekfreetrial",
        name: "Vantage",
        discountPrice: 0,
        localizedDiscountPriceString: "$0",
        originalPrice: 12.99,
        localizedOriginalPriceString: "$12.99",
        currencyCode: "USD",
        numberOfPeriods: 1,
        periodLength: .week,
        subscriptionType: .yearlyVantageUS7199,
        subscriptionPlan: .vantage,
        productIdentifier: "com.example.app.yearly.vantage.us7199"
    )
    private let premiumUS3999FreeTrialPromotionalOffer = PromotionalOfferDiscount(
        id: "com.example.app.yearly.premium.us3999.1weekfreetrial",
        name: "Premium",
        discountPrice: 0,
        localizedDiscountPriceString: "$0",
        originalPrice: 39.99,
        localizedOriginalPriceString: "$39.99",
        currencyCode: "USD",
        numberOfPeriods: 1,
        periodLength: .week,
        subscriptionType: .yearlyPremiumUS3999,
        subscriptionPlan: .premium,
        productIdentifier: "com.example.app.yearly.premium.us.3999"
    )
    private var subject: TrialState!

    override func setUp() {
        super.setUp()
        subject = createTrialState(
            userHasActiveSubscription: false,
            isInstitutionLogin: false,
            isEligibleForIntroOffer: false,
            remoteConfigurationValue: nil,
            isVantageVisibilityPolicyEnabled: false,
            promotionalOffers: []
        )
    }

    func testReturnsNilWhenUserHasActiveSubscription() {
        subject = createTrialState(userHasActiveSubscription: true, isInstitutionLogin: false, isEligibleForIntroOffer: true, remoteConfigurationValue: nil, isVantageVisibilityPolicyEnabled: true, promotionalOffers: [])
        XCTAssertNil(subject)
    }

    func testReturnsNilWhenInstitutionLoginAndUserEligibleForIntroOffer() {
        subject = createTrialState(userHasActiveSubscription: false, isInstitutionLogin: true, isEligibleForIntroOffer: true, remoteConfigurationValue: nil, isVantageVisibilityPolicyEnabled: true, promotionalOffers: [])
        XCTAssertNil(subject)
    }

    func testReturnsNilWhenIntroOfferEligibilityIsUnknown() {
        subject = createTrialState(userHasActiveSubscription: false, isInstitutionLogin: false, isEligibleForIntroOffer: nil, remoteConfigurationValue: nil, isVantageVisibilityPolicyEnabled: true, promotionalOffers: [])
        XCTAssertNil(subject)
    }

    func testReturnsNilWhenUserNotEligibleForIntroOfferAndNoEligiblePromotionalOffers() {
        subject = createTrialState(userHasActiveSubscription: false, isInstitutionLogin: false, isEligibleForIntroOffer: false, remoteConfigurationValue: nil, isVantageVisibilityPolicyEnabled: true, promotionalOffers: [])
        XCTAssertNil(subject)
    }

    func testReturnsIntroductoryOfferWhenEligibleAndNoPromotionalOffers() {
        subject = createTrialState(userHasActiveSubscription: false, isInstitutionLogin: false, isEligibleForIntroOffer: true, remoteConfigurationValue: nil, isVantageVisibilityPolicyEnabled: true, promotionalOffers: [])
        XCTAssertEqual(subject, .introductoryOffer)
    }

    func testReturnsPremiumPromotionalOfferWithPremiumRemoteConfigurationAndUserNotEligibleForIntroOffer() {
        subject = createTrialState(userHasActiveSubscription: false, isInstitutionLogin: false, isEligibleForIntroOffer: false, remoteConfigurationValue: .trialScreenPremiumVantage(.premium), isVantageVisibilityPolicyEnabled: true, promotionalOffers: [premiumFreeTrialPromotionalOffer, vantageFreeTrialPromotionalOffer])
        XCTAssertEqual(subject, .promotionalOffer(offer: premiumFreeTrialPromotionalOffer))
    }

    func testReturnsVantagePromotionalOfferWithVantageRemoteConfigurationAndUserNotEligibleForIntroOffer() {
        subject = createTrialState(userHasActiveSubscription: false, isInstitutionLogin: false, isEligibleForIntroOffer: false, remoteConfigurationValue: .trialScreenPremiumVantage(.vantage), isVantageVisibilityPolicyEnabled: true, promotionalOffers: [premiumFreeTrialPromotionalOffer, vantageFreeTrialPromotionalOffer])
        XCTAssertEqual(subject, .promotionalOffer(offer: vantageFreeTrialPromotionalOffer))
    }

    func testForceOldExperimentUsersToSeePaywallWhenPayloadContainsCampaign() throws {
        let placement = "campaign_trigger"
        let trialScreenData = try createTrialScreenDictionary(screen: try createTrialScreen(product: "vantage", paywallCampaign: placement))
        subject = createTrialState(
            isEligibleForIntroOffer: true,
            remoteConfigurationValue: .trialScreenPremiumVantage(.vantage),
            isVantageVisibilityPolicyEnabled: true,
            showNewTrialScreen: true,
            trialScreenData: [trialScreenData]
        )
        XCTAssertEqual(subject, .paywallCampaign(campaign: placement))
    }

    func testForceOldExperimentUsersToSeePaywallFallsBackToNativeWhenPayloadCampaignMissing() throws {
        let trialScreenData = try createTrialScreenDictionary(screen: try createTrialScreen(product: "vantage", paywallCampaign: nil))
        subject = createTrialState(
            isEligibleForIntroOffer: true,
            remoteConfigurationValue: .trialScreenPremiumVantage(.vantage),
            isVantageVisibilityPolicyEnabled: true,
            showNewTrialScreen: true,
            trialScreenData: [trialScreenData]
        )
        XCTAssertEqual(subject, .introductoryOffer)
    }

    func testShowingPaywallCampaignWhenEligibleForIntroOffer() {
        subject = createTrialState(isEligibleForIntroOffer: true, remoteConfigurationValue: nil, isVantageVisibilityPolicyEnabled: true, promotionalOffers: [], showNewTrialScreen: false, paywallCampaign: "campaign_trigger")
        XCTAssertEqual(subject, .paywallCampaign(campaign: "campaign_trigger"))
    }

    func testNotShowingPaywallCampaignWhenEligibleForPromotionalOffer() {
        subject = createTrialState(userHasActiveSubscription: false, isInstitutionLogin: false, isEligibleForIntroOffer: false, remoteConfigurationValue: nil, isVantageVisibilityPolicyEnabled: true, promotionalOffers: [premiumFreeTrialPromotionalOffer], paywallCampaign: "")
        XCTAssertEqual(subject, .promotionalOffer(offer: premiumFreeTrialPromotionalOffer))
    }

    func testPricingExperimentUS4999UsersSeeingPaywallWhenACampaignIsSpecified() {
        let pricingExperiments = [
            createPricingExperimentData(paywallCampaign: "valid_campaign_us4999", cohort: "premiumUS4999", productIdentifiers: []),
            createPricingExperimentData(paywallCampaign: "valid_campaign_us3999", cohort: "premiumUS3999", productIdentifiers: [])
        ]
        subject = createTrialState(userHasActiveSubscription: false, isEligibleForIntroOffer: true, remoteConfigurationValue: .trialScreenPremiumVantage(.premiumUS4999), isVantageVisibilityPolicyEnabled: false, paywallCampaign: "this_should_not_be_shown", pricingExperimentData: pricingExperiments)
        XCTAssertEqual(subject, .paywallCampaign(campaign: "valid_campaign_us4999"))
    }

    func testTrialScreenShowingOldTrialScreenWithUSVantagePricedAt7199() throws {
        let screen = try createTrialScreen(product: "vantage")
        let trialScreenData = try createTrialScreenDictionary(screen: screen)

        subject = createTrialState(isEligibleForIntroOffer: false, remoteConfigurationValue: .trialScreenPremiumVantage(.vantageUS7199), isVantageVisibilityPolicyEnabled: true, promotionalOffers: [vantageFreeTrialPromotionalOffer, vantageUS7199FreeTrialPromotionalOffer], showNewTrialScreen: false, trialScreenData: [trialScreenData])

        XCTAssertEqual(subject, .promotionalOffer(offer: vantageUS7199FreeTrialPromotionalOffer))
    }

    func testTrialScreenShowingOldTrialScreenWithPromotionalOfferUSPremiumPricedAt3999() {
        subject = createTrialState(isEligibleForIntroOffer: false, remoteConfigurationValue: .trialScreenPremiumVantage(.premiumUS3999), isVantageVisibilityPolicyEnabled: true, promotionalOffers: [premiumFreeTrialPromotionalOffer, premiumPromotionalOffer, vantageUS7199FreeTrialPromotionalOffer, premiumUS3999FreeTrialPromotionalOffer])

        XCTAssertEqual(subject, .promotionalOffer(offer: premiumUS3999FreeTrialPromotionalOffer))
    }
}

extension TrialStateTests {
    private func createTrialState(userHasActiveSubscription: Bool = false,
                                  isInstitutionLogin: Bool = false,
                                  isEligibleForIntroOffer: Bool? = nil,
                                  remoteConfigurationValue: RemoteConfigurationValue? = nil,
                                  isVantageVisibilityPolicyEnabled: Bool = false,
                                  promotionalOffers: [PromotionalOfferDiscount] = [],
                                  showNewTrialScreen: Bool = false,
                                  trialScreenData: [[String: Any]] = [],
                                  paywallCampaign: String = "",
                                  pricingExperimentData: [[String: Any]] = []) -> TrialState? {
        return TrialState(userHasActiveSubscription: userHasActiveSubscription,
                          isInstitutionLogin: isInstitutionLogin,
                          isEligibleForIntroOffer: isEligibleForIntroOffer,
                          remoteConfigurationValue: remoteConfigurationValue,
                          isVantageVisibilityPolicyEnabled: isVantageVisibilityPolicyEnabled,
                          promotionalOffers: promotionalOffers,
                          showNewTrialScreen: showNewTrialScreen,
                          trialScreenData: trialScreenData,
                          paywallCampaign: paywallCampaign,
                          pricingExperimentData: pricingExperimentData)
    }

    private func createTrialScreenData(product: String, paywallCampaign: String? = nil) -> [String: Any] {
        return [
            "product": product,
            "superwallCampaign": paywallCampaign as Any,
            "cohort": "",
            "header": [
                "title": ""
            ],
            "features": [],
            "review": [
                "numberOfReviews": "",
                "averageRating": ""
            ]
        ]
    }

    private func createPricingExperimentData(paywallCampaign: String?, cohort: String, productIdentifiers: [String]) -> [String: Any] {
        return [
            "superwallCampaign": paywallCampaign as Any,
            "cohort": cohort,
            "productIdentifiers": productIdentifiers
        ]
    }

    private func createTrialScreen(product: String, paywallCampaign: String? = nil) throws -> FeatureFlagTrialScreen {
        let data = try JSONSerialization.data(withJSONObject: createTrialScreenData(product: product, paywallCampaign: paywallCampaign), options: [.fragmentsAllowed, .sortedKeys])
        return try JSONDecoder().decode(FeatureFlagTrialScreen.self, from: data)
    }

    private func createTrialScreenDictionary(screen: FeatureFlagTrialScreen) throws -> [String: Any] {
        let data = screen.toData() ?? Data()
        return try (JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any]) ?? [:]
    }
}
