//
//  SubscriptionsCellModelFactory.swift
//  
//
//  Created by Andrey Dubenkov on 25/07/2019.
//  Copyright © 2019 . All rights reserved.
//

import Foundation

enum SubscriptionsCellModelFactory {
    static func makeCellModels(state: SubscriptionsState) -> [SubscriptionCellModel] {
        guard let options = state.options else {
            return []
        }

        return options.map { option in
            var isSelected = false
            var isCurrent = false
            if let selected = state.selectedOption {
                isSelected = option == selected
            }
            if let current = state.currentOption {
                isCurrent = option == current
            }
            return SubscriptionCellModel(product: option,
                                         isSelected: isSelected,
                                         isCurrent: isCurrent)
        }
    }
}
