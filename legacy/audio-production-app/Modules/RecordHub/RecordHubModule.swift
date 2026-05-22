//
//  Created by Andrey Dubenkov on 13/11/2019
//  Copyright © 2019 . All rights reserved.
//

import UIKit

protocol RecordHubModuleInput: class {
    var state: RecordHubState { get }
    func update(animated: Bool)
}

protocol RecordHubModuleOutput: class {
    func recordHubModuleDidClose(_ moduleInput: RecordHubModuleInput)
}

final class RecordHubModule {

    var input: RecordHubModuleInput {
        return presenter
    }
    weak var output: RecordHubModuleOutput? {
        get {
            return presenter.output
        }
        set {
            presenter.output = newValue
        }
    }
    let viewController: RecordHubViewController
    private let presenter: RecordHubPresenter

    init(with projectID: Int, takeID: Int) {
        let state = RecordHubState(projectID: projectID, takeID: takeID)
        let viewModel = RecordHubViewModel(state: state)
        let presenter = RecordHubPresenter(state: state, dependencies: ServiceContainer())
        let viewController = RecordHubModule.makeViewController(viewModel: viewModel, output: presenter)

        presenter.view = viewController
        self.viewController = viewController
        self.presenter = presenter
    }

    class func makeViewController(viewModel: RecordHubViewModel, output: RecordHubPresenter) -> RecordHubViewController {
        // swiftlint:disable force_cast
        let storyboard = UIStoryboard(name: "RecordHubStoryboard", bundle: nil)
        let view = storyboard.instantiateViewController(withIdentifier: "RecordHubViewController") as! RecordHubViewController
        view.viewModel = viewModel
        view.output = output
        view.visualisationOutput = output
        return view
    }
}
