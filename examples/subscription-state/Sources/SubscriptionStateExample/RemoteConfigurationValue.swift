import Foundation

enum RemoteConfigurationValue {
    case bool(Bool)
    case trialScreenPremiumVantage(TrialScreenRemoteConfig?)
}

enum TrialScreenRemoteConfig: String {
    case premium
    case vantage
    case vantageUS7199
    case premiumUS3999
    case premiumUS4499
    case premiumUS4999
    case premiumControl
    case vantageControl
    case vantageUS7199Control
    case premiumUS3999Control
    case premiumUS4499Control
    case premiumUS4999Control
}
