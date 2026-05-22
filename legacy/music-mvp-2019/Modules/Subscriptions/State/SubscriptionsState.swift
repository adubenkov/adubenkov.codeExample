//
//  Created by Andrey Dubenkov on 25/07/2019
//  Copyright © 2019 . All rights reserved.
//
import UIKit

final class SubscriptionsState {

    let scenarioType: SubscriptionScenarioType

    var isLoading: Bool = false
    var wasDowngraded: Bool = false
    var options: [SubscriptionProduct]?
    var selectedOption: SubscriptionProduct?
    var currentOption: SubscriptionProduct?

    init(scenarioType: SubscriptionScenarioType) {
        self.scenarioType = scenarioType
    }
}
