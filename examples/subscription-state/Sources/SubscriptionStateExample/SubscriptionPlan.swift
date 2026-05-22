import Foundation

enum SubscriptionPlan: String, Comparable {
    case pro
    case premium
    case vantage
    case none

    static func < (lhs: SubscriptionPlan, rhs: SubscriptionPlan) -> Bool {
        switch rhs {
        case .none: return false
        case .pro: return lhs == .none
        case .premium: return lhs == .none || lhs == .pro
        case .vantage: return lhs == .none || lhs == .pro || lhs == .premium
        }
    }
}
