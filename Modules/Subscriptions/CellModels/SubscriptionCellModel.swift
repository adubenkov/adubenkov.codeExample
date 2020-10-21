//
//  SubscriptionsCellModel.swift
//  
//
//  Created by Andrey Dubenkov on 25/07/2019.
//  Copyright © 2019 . All rights reserved.
//

import Foundation
import StoreKit

final class SubscriptionCellModel: Equatable {
    let subscriptionName: String
    let price: String
    let subDescription: String
    let isSelected: Bool
    let isCurrent: Bool
    let type: SubscriptionProductType

    init(product: SubscriptionProduct,
         isSelected: Bool,
         isCurrent: Bool) {
        subscriptionName = product.name
        subDescription = product.description
        price = isCurrent ? "Current plan" : "\(product.price) per month"
        type = product.type
        self.isSelected = isSelected
        self.isCurrent = isCurrent
    }

    static func == (lhs: SubscriptionCellModel, rhs: SubscriptionCellModel) -> Bool {
        return lhs.subscriptionName == rhs.subscriptionName &&
            lhs.price == rhs.price &&
            lhs.subDescription == rhs.subDescription &&
            lhs.isSelected == rhs.isSelected &&
            lhs.isCurrent == rhs.isCurrent &&
            lhs.type == rhs.type
    }
}
