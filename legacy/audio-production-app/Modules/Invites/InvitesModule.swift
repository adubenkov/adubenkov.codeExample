//
//  Created by Andrey Dubenkov on 26/06/2019
//  Copyright © 2019 . All rights reserved.
//

import UIKit

protocol InvitesModuleInput: AnyObject {
    var state: InvitesState { get }
    func update(animated: Bool)
    func continueInviteAccepting()
}

protocol InvitesModuleOutput: AnyObject {
    func invitesModuleDidRequestShowSideMenu(_ moduleInput: InvitesModuleInput)
    func invitesModule(_ moduleInput: InvitesModuleInput, didFailWith error: Error)
    func invitesModuleDidAcceptInvite(_ moduleInput: InvitesModuleInput)
    func invitesModuleDidDeclineInvite(_ moduleInput: InvitesModuleInput)
    func invitesModuleDidResendInvite(_ moduleInput: InvitesModuleInput)
    func invitesModuleDidRequestUpgradeSubscription(_ moduleInput: InvitesModuleInput)
}

final class InvitesModule {
    var input: InvitesModuleInput {         return presenter
    }
    weak var output: InvitesModuleOutput? {
        get {
            return presenter.output
        }
        set {
            presenter.output = newValue
        }
    }
    let viewController: InvitesViewController
    private let presenter: InvitesPresenter

    init() {
        let state = InvitesState()
        let viewModel = InvitesViewModel(state: state)
        let presenter = InvitesPresenter(state: state, dependencies: ServiceContainer())
        let viewController = InvitesViewController(viewModel: viewModel, output: presenter)

        presenter.view = viewController
        self.viewController = viewController
        self.presenter = presenter
    }
}
