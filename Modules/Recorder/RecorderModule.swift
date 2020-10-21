//
//  Created by Andrey Dubenkov on 01/04/2020
//  Copyright © 2020 . All rights reserved.
//

import UIKit

protocol RecorderModuleInput: class {
    var state: RecorderState { get }
    func update(animated: Bool)
}

protocol RecorderModuleOutput: class {
    func recorderModuleDidClose(_ moduleInput: RecorderModuleInput)
    func fileIsReady(_ url: URL)
}

final class RecorderModule {
    var input: RecorderModuleInput {
        return presenter
    }

    weak var output: RecorderModuleOutput? {
        get {
            return presenter.output
        }
        set {
            presenter.output = newValue
        }
    }

    let viewController: RecorderViewController

    private let presenter: RecorderPresenter

    init() {
        let state = RecorderState()
        let viewModel = RecorderViewModel(state: state)
        let presenter = RecorderPresenter(state: state, dependencies: ServiceContainer())
        let viewController = RecorderModule.makeViewController(viewModel: viewModel, output: presenter)
        presenter.view = viewController
        self.viewController = viewController
        self.presenter = presenter
    }

    class func makeViewController(viewModel: RecorderViewModel, output: RecorderPresenter) -> RecorderViewController {
        // swiftlint:disable force_cast
        let storyboard = UIStoryboard(name: "Recorder", bundle: nil)
        let view = storyboard.instantiateViewController(withIdentifier: "RecorderViewController") as! RecorderViewController
        view.viewModel = viewModel
        view.output = output
        view.plotOutput = output
        return view
    }
}
