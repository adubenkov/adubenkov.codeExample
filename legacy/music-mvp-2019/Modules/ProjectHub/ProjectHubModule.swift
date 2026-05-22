//
//  Created by Andrey Dubenkov on 10/11/2019
//  Copyright © 2019 . All rights reserved.
//

import UIKit

protocol ProjectHubModuleInput: class {
    var state: ProjectHubState { get }
    func update(animated: Bool)
}

protocol ProjectHubModuleOutput: class {
    func projectHubModuleDidClose(_ moduleInput: ProjectHubModuleInput)
}

final class ProjectHubModule {

    var input: ProjectHubModuleInput {
        return presenter
    }
    weak var output: ProjectHubModuleOutput? {
        get {
            return presenter.output
        }
        set {
            presenter.output = newValue
        }
    }
    let viewController: ProjectHubViewController
    private let presenter: ProjectHubPresenter

    init(with projectID: Int, scenario: ProjectHubScenario = .noOptions) {
        let state = ProjectHubState(projectID: projectID, scenario: scenario)
        let viewModel = ProjectHubViewModel(state: state)
        let presenter = ProjectHubPresenter(state: state, dependencies: ServiceContainer())
        let viewController = ProjectHubModule.makeViewController(viewModel: viewModel, output: presenter)
        presenter.view = viewController
        self.viewController = viewController
        self.presenter = presenter
    }

    class func makeViewController(viewModel: ProjectHubViewModel, output: ProjectHubPresenter) -> ProjectHubViewController {
        // swiftlint:disable force_cast
        let storyboard = UIStoryboard(name: "ProjectHubStoryboard", bundle: nil)
        let view = storyboard.instantiateViewController(withIdentifier: "ProjectHubViewController") as! ProjectHubViewController
        view.viewModel = viewModel
        view.output = output
        view.visualisationOutput = output
        return view
    }
}

enum ProjectHubScenario: Equatable {
    case noOptions
    case toUserTakes(userID: Int)
    case toComment
    case toInvite(userID: Int)
}
