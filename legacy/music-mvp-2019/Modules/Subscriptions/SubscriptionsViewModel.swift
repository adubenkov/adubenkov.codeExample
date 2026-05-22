//
//  Created by Andrey Dubenkov on 25/07/2019
//  Copyright © 2019 . All rights reserved.
//
import Foundation
import UIKit

enum SubscriptionScenarioType {
    case fromProfile
    case twoOptions
    case oneOption
    case noOption
}

enum SubscriptionCellType {
    case full
    case mini
}

struct SubscriptionsViewModel: Equatable {
    let subscriptionsCellModels: [SubscriptionCellModel]
    let isLoading: Bool
    let shouldRemoveSecondLabel: Bool
    let cellType: SubscriptionCellType
    let title: String
    let subTitle: String
    let optionsTitle: String
    let scrollViewHeight: CGFloat
    let headerViewHeight: CGFloat

    init(state: SubscriptionsState) {
        isLoading = state.isLoading
        subscriptionsCellModels = SubscriptionsCellModelFactory.makeCellModels(state: state)
        switch state.scenarioType {
        case .fromProfile:
            title = "Your Account"
            subTitle = """
                Note: If you’re downgrading you’ll be asked \
                to delete or leave projects to meet the limits\n of the selected level.
                """
            optionsTitle = ""
            scrollViewHeight = 760
            headerViewHeight = 400 //435
        case .twoOptions:
            title = "Hey there Rockstar"
            subTitle = """
                You’ve reached the 10 project limit\n \
                for the free account, thanks for being an\n active member!
                """
            optionsTitle = "Next level options"
            scrollViewHeight = 830
            headerViewHeight = 400
        case .oneOption:
            title = "Hello Friend"
            subTitle = """
                You’ve reached the limit of projects you can be active\n \
                in for your account level, you’re pretty rad!
                """
            optionsTitle = "Next level options"
            scrollViewHeight = 800
            headerViewHeight = 400
        case .noOption:
            title = "Your Account"
            subTitle = """
                Note: If you’re downgrading you’ll be asked \
                to delete or leave projects to meet the limits\n of the selected level.
                """
            optionsTitle = ""
            scrollViewHeight = 760
            headerViewHeight = 400 //435
        }

        switch state.scenarioType {
        case .fromProfile, .noOption:
            shouldRemoveSecondLabel = true
            cellType = .mini
        default:
            shouldRemoveSecondLabel = false
            cellType = .full
        }
    }

    static func == (lhs: SubscriptionsViewModel, rhs: SubscriptionsViewModel) -> Bool {
        return lhs.isLoading == rhs.isLoading &&
               lhs.shouldRemoveSecondLabel == rhs.shouldRemoveSecondLabel &&
               lhs.subscriptionsCellModels == rhs.subscriptionsCellModels &&
               lhs.title == rhs.title &&
               lhs.subTitle == rhs.subTitle &&
               lhs.optionsTitle == rhs.optionsTitle &&
               lhs.cellType == rhs.cellType &&
               lhs.scrollViewHeight == rhs.scrollViewHeight &&
               lhs.headerViewHeight == rhs.headerViewHeight
    }
}
