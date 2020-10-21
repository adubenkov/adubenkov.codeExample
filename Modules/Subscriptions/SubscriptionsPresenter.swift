//
//  Created by Andrey Dubenkov on 25/07/2019
//  Copyright © 2019 . All rights reserved.
//

import Foundation
import StoreKit

final class SubscriptionsPresenter {
    typealias Dependencies = HasApiService &
                             HasStoreService &
                             HasReachabilityService &
                             HasRealmService

    weak var view: SubscriptionsViewInput?
    weak var output: SubscriptionsModuleOutput?

    var state: SubscriptionsState

    private let dependencies: Dependencies

    init(state: SubscriptionsState, dependencies: Dependencies) {
        self.state = state
        self.dependencies = dependencies
    }

    // MARK: - Private

    private func fetchSubscriptionOptionsInBackground(completion: (() -> Void)? = nil) {
        state.isLoading = true
        update(animated: false)
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                return
            }
            self.fetchOptions { [weak self] options in
                guard let self = self else {
                    return
                }

                DispatchQueue.main.async {
                    self.state.options = self.filterOptions(options)
                    self.preSelectOptions()
                    self.selectCurrentOptions()
                    completion?()
                }
            }
        }
    }

    private func fetchOptions(completion: @escaping ([SubscriptionProduct]) -> Void) {
        guard dependencies.reachabilityService.isReachable else {
            completion([])
            return
        }

        dependencies.storeService.retriveProductsInfo { products in
            let options = products
            completion(options)
        }
    }

    private func filterOptions(_ options: [SubscriptionProduct]) -> [SubscriptionProduct] {
        var filteredOptions = options
        switch self.state.scenarioType {
        case .fromProfile, .noOption:
            let freeOption = SubscriptionProduct(product: nil)
            filteredOptions.append(freeOption)
        case .oneOption:
            filteredOptions = filteredOptions.filter {
                $0.type == .unlimitedTest ||
                $0.type == .unlimited
            }
        case .twoOptions:
            break
        }
        return filteredOptions
    }

    private func preSelectOptions() {
        if let next = dependencies.realmService.getNextProductType() {
            state.selectedOption = state.options?.first {
                $0.type == next
            }
        }
    }

    private func selectCurrentOptions() {
        if let current = dependencies.realmService.getCurrentProductType() {
            state.currentOption = state.options?.first {
                $0.type == current
            }
        }
    }

    private func buyProduct(product: SubscriptionProduct) {
        guard dependencies.reachabilityService.isReachable else {
            let message = "Please connect to the internet"
            output?.subscriptionsModule(self, didFailWith: SubscriptionsModuleError.productNotBought(message: message))
            return
        }

        guard doesPlanFit(product) else {
            let message = getPlanDoesntFitErrorMessage(product)
            output?.subscriptionsModule(self, didFailWith: SubscriptionsModuleError.productNotBought(message: message))
            return
        }

        state.isLoading = true
        update(animated: true)
        dependencies.storeService.purchaseProduct(product, success: { [weak self] wasDowngraded in
            guard let self = self else {
                return
            }
            self.state.wasDowngraded = wasDowngraded
            self.state.isLoading = false
            self.update(animated: true)

            self.output?.subscriptionsModuleDidBoughtProduct(self)
        }, failure: { [weak self] error in
            guard let self = self else {
                return
            }

            self.state.isLoading = false
            self.update(animated: true)

            self.output?.subscriptionsModule(self, didFailWith: SubscriptionsModuleError.productNotBought(message: error.localizedDescription))
        })
    }

    private func isProductCurrent(_ product: SubscriptionProduct?) -> Bool {
        guard let currentPlan = dependencies.realmService.getCurrentPlan() else {
            return false
        }
        if currentPlan.name == SubscriptionProductType.free.rawValue && product == nil {
            return true
        }

        return currentPlan.name == product?.type.rawValue
    }

    private func doesPlanFit(_ product: SubscriptionProduct) -> Bool {
        let currentProjectsCount = dependencies.realmService.getCurrentProjectsCount()
        let newPlanProjectsCount = product.type.getProjectCount()
        return newPlanProjectsCount >= currentProjectsCount
    }

    private func getProjectCountToFitPlan(_ product: SubscriptionProduct) -> Int {
        let currentProjectsCount = dependencies.realmService.getCurrentProjectsCount()
        let newPlanProjectsCount = product.type.getProjectCount()
        return currentProjectsCount - newPlanProjectsCount
    }

    private func getPlanDoesntFitErrorMessage(_ product: SubscriptionProduct) -> String {
        let message = """
            To subscribe to the \(product.name) plan, \
            please either leave a project you've been invite to, \
            or delete a project you've created.
            """
        return message
    }

    private func product(withType type: SubscriptionProductType) -> SubscriptionProduct? {
        return state.options?.first { $0.type == type }
    }

    func optionSelected(option: SubscriptionProduct) {
        state.selectedOption = option
        self.update(animated: true)
    }
}

// MARK: - SubscriptionsViewOutput

extension SubscriptionsPresenter: SubscriptionsViewOutput {
    func viewDidLoad() {
        update(animated: false)
        fetchSubscriptionOptionsInBackground { [weak self] in
            guard let self = self else {
                return
            }
            self.state.isLoading = false
            self.update(animated: true)
        }
    }

    func closeEventTriggered() {
        output?.subscriptionsModuleDidRequestClose(self)
    }

    func selectionEventTriggered(with cellModel: SubscriptionCellModel) {
        switch self.state.scenarioType {
        case .fromProfile, .noOption:
            buyingEventTriggered(with: cellModel)
        case .twoOptions, .oneOption:
            guard let product = product(withType: cellModel.type) else {
                return
            }
            optionSelected(option: product)
        }
    }

    func buyingEventTriggered(with cellModel: SubscriptionCellModel?) {
        func failure() {
            let message = "Please select option"
            output?.subscriptionsModule(self, didFailWith: SubscriptionsModuleError.productNotBought(message: message))
        }

        func openSystemSubscriptions() {
            if let url = URL(string: "https://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/manageSubscriptions") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }

        guard let cellModel = cellModel else {
            failure()
            return
        }
        guard let product = product(withType: cellModel.type) else {
            failure()
            return
        }

        guard product.type != .free else {
            openSystemSubscriptions()
            return
        }
        buyProduct(product: product)
    }
}

// MARK: - SubscriptionsModuleInput

extension SubscriptionsPresenter: SubscriptionsModuleInput {

    func update(animated: Bool) {
        let viewModel = SubscriptionsViewModel(state: state)
        view?.update(with: viewModel, animated: animated)
    }
}

private enum SubscriptionsModuleError {
    case optionsNotFetched(message: String)
    case productNotBought(message: String)
}

extension SubscriptionsModuleError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .optionsNotFetched(let message):
            return message
        case .productNotBought(let message):
            return message
        }
    }
}
