//
//  Created by Andrey Dubenkov on 01/04/2020
//  Copyright © 2020 . All rights reserved.
//

import DeviceKit
import UIKit

protocol RecorderViewInput: class {
    @discardableResult
    func update(with viewModel: RecorderViewModel, animated: Bool) -> Bool
    func setNeedsUpdate()
    func showError(_ error: Error)
    func showMessage(_ message: String, title: String, completion: (() -> Void)?)
    func exit()
}

protocol RecorderViewOutput: class {
    func viewDidLoad()

    func recordButtonPressed()
    func undoButtonPressed()
    func rewindButtonPressed()
    func playButtonPressed()
    func saveButtonPressed()
}

final class RecorderViewController: UIViewController {
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var undoButton: UIButton!
    @IBOutlet var rewindButton: UIButton!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var timerLabel: UILabel!
    @IBOutlet var saveButton: UIButton!
    @IBOutlet var containerView: UIView!

    var viewModel: RecorderViewModel
    var output: RecorderViewOutput?
    var plotOutput: RecorderPlotViewOutput?

    var needsUpdate: Bool = true

    // MARK: - Lifecycle

    init(viewModel: RecorderViewModel, output: RecorderViewOutput) {
        self.viewModel = viewModel
        self.output = output
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        viewModel = RecorderViewModel(state: RecorderState())
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configView()
        output?.viewDidLoad()
    }

    // MARK: - Private

    private func configView() {
        let device = Device.current
        if device.diagonal < 4.7 {
            timerLabel.font = timerLabel.font.withSize(29)
        }
//        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        recordButton.isHidden = false
        saveButton.layer.cornerRadius = 25
    }

    private func lockInterface(_ isWorking: Bool) {
        saveButton.isEnabled = !isWorking
        rewindButton.isEnabled = !isWorking
        playButton.isEnabled = !isWorking
        undoButton.isEnabled = !isWorking
//        self.recordButton.isEnabled = !isWorking
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {

        case "toRecorderPlotview":
            guard let plotView = segue.destination as? RecorderPlotViewController else {
                return
            }
            plotOutput?.input = plotView
            plotView.output = plotOutput
        default:
            break
        }
    }

    // MARK: - Actions

    @IBAction func recordButtonPressed(_ sender: Any) {
        output?.recordButtonPressed()
    }

    @IBAction func undoButtonPressed(_ sender: Any) {
        output?.undoButtonPressed()
    }

    @IBAction func rewindButtonPressed(_ sender: Any) {
        output?.rewindButtonPressed()
    }

    @IBAction func playButtonPressed(_ sender: Any) {
        output?.playButtonPressed()
    }

    @IBAction func saveButtonPressed(_ sender: Any) {
        output?.saveButtonPressed()
    }
}

// MARK: - RecorderViewInput

extension RecorderViewController: RecorderViewInput, ViewUpdatable {
    func exit() {
        navigationController?.popViewController(animated: true)
    }

    func showError(_ error: Error) {
        showAlert(message: error.localizedDescription)
    }

    func showMessage(_ message: String, title: String, completion: (() -> Void)?) {
        showAlert(message: message, title: title, completion: completion)
    }

    func setNeedsUpdate() {
        needsUpdate = true
    }

    @discardableResult
    func update(with viewModel: RecorderViewModel, animated: Bool) -> Bool {
        let oldViewModel = self.viewModel
        guard needsUpdate || viewModel != oldViewModel else {
            return false
        }
        self.viewModel = viewModel

        // update view

        update(new: viewModel, old: oldViewModel, keyPath: \.currentTimeString) { currentTimeString in
            self.timerLabel.text = currentTimeString
        }

        updateLoadingState(viewModel: viewModel, oldViewModel: oldViewModel, animated: animated)
        updateRenderingState(viewModel: viewModel, oldViewModel: oldViewModel, animated: animated)
        updateRenderingProgress(viewModel: viewModel, oldViewModel: oldViewModel, animated: animated)
        update(new: viewModel, old: oldViewModel, keyPath: \.isUndoPossible) { isUndoPossible in
            undoButton.isHidden = !isUndoPossible
        }

        update(new: viewModel, old: oldViewModel, keyPath: \.isPlaying) { isPlaying in
            let buttonState: PlayButtonState = isPlaying ? .pauseButton : .playButton
            self.playButton.setImage(UIImage(named: buttonState.rawValue), for: .normal)
        }

        update(new: viewModel, old: oldViewModel, keyPath: \.isRecording) { isRecording in
            let buttonState: RecordButtonState = !isRecording ? .recordButton : .stopButton
            self.recordButton.setImage(UIImage(named: buttonState.rawValue), for: .normal)
            lockInterface(isRecording)
        }
        needsUpdate = false

        return true
    }

    private func updateRenderingState(viewModel: RecorderViewModel,
                                      oldViewModel: RecorderViewModel,
                                      animated: Bool) {
        func showProgress(_ isRendering: Bool) {
//            view.isUserInteractionEnabled = !isRendering
            DispatchQueue.main.async {
                if isRendering {
                    self.showRenderingHUD(animated: false)
                } else {
                    self.hideRenderingHUD(animated: false)
                }
            }
        }

        update(new: viewModel, old: oldViewModel, keyPath: \.isRendering) { isRendering in
            lockInterface(isRendering)
            if isRendering {
                showProgress(true)
            } else if animated {
                UIView.animate(withDuration: 0.3) {
                    showProgress(false)
                }
            } else {
                showProgress(false)
            }
        }
    }

    private func updateRenderingProgress(viewModel: RecorderViewModel,
                                         oldViewModel: RecorderViewModel,
                                         animated: Bool) {
        update(new: viewModel, old: oldViewModel, keyPath: \.renderingProgress) { renderingProgress in
            updateRenderingHUD(withProgress: Float(renderingProgress))
        }
    }

    private func updateLoadingState(viewModel: RecorderViewModel,
                                    oldViewModel: RecorderViewModel,
                                    animated: Bool) {
        func showLoading(_ isLoading: Bool) {
//            view.isUserInteractionEnabled = !isLoading
            if isLoading {
                showLoadingHUD(animated: false)
            } else {
                hideLoadingHUD(animated: false)
            }
        }

        update(new: viewModel, old: oldViewModel, keyPath: \.isLoading) { isLoading in
            lockInterface(isLoading)
            if isLoading {
                showLoading(true)
            } else if animated {
                UIView.animate(withDuration: 0.3) {
                    showLoading(false)
                }
            } else {
                showLoading(false)
            }
        }
    }
}
