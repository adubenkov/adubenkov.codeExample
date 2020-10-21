//
//  SubscriptionsModule.swift
//  
//
//  Created by Andrey Dubenkov on 25/07/2019
//  Copyright © 2019 . All rights reserved.
//

import UIKit

protocol SubscriptionsModuleInput: AnyObject {
    var state: SubscriptionsState { get }
    func update(animated: Bool)
}

protocol SubscriptionsModuleOutput: AnyObject {
    func subscriptionsModuleDidRequestClose(_ moduleInput: SubscriptionsModuleInput)
    func subscriptionsModule(_ moduleInput: SubscriptionsModuleInput, didFailWith error: Error)
    func subscriptionsModuleDidBoughtProduct(_ moduleInput: SubscriptionsModuleInput)
}

final class SubscriptionsModule {
    var input: SubscriptionsModuleInput {
        return presenter
    }
    weak var output: SubscriptionsModuleOutput? {
        get {
            return presenter.output
        }
        set {
            presenter.output = newValue
        }
    }
    let viewController: SubscriptionsViewController
    private let presenter: SubscriptionsPresenter

    init(scenario: SubscriptionScenarioType) {
        let state = SubscriptionsState(scenarioType: scenario)
        let viewModel = SubscriptionsViewModel(state: state)
        let presenter = SubscriptionsPresenter(state: state, dependencies: ServiceContainer())
        let viewController = SubscriptionsViewController(viewModel: viewModel, output: presenter)

        presenter.view = viewController
        self.viewController = viewController
        self.presenter = presenter
    }
}
