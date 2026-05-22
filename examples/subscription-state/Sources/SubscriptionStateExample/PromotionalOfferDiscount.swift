import Foundation

struct PromotionalOfferDiscount: Equatable {
    let id: String
    let name: String
    let discountPrice: Decimal
    let localizedDiscountPriceString: String
    let originalPrice: Decimal
    let localizedOriginalPriceString: String
    let currencyCode: String?
    let numberOfPeriods: Int
    let periodLength: OfferPeriod
    let subscriptionType: SubscriptionType
    let subscriptionPlan: SubscriptionPlan
    let productIdentifier: String
}
