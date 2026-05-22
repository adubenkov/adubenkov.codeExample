//
//  Created by Andrey Dubenkov on 13/11/2019
//  Copyright © 2019 . All rights reserved.
//

import DeviceKit
import UIKit

enum RecordButtonState: String {
    case recordButton = "RecordButton"
    case stopButton = "StopRecord"
    case hidden
}

protocol RecordHubViewInput: class {
    @discardableResult
    func update(with viewModel: RecordHubViewModel, animated: Bool) -> Bool
    func setNeedsUpdate()
    func presentView(view: UIViewController)
    func showError(_ error: Error)
    func showMessage(_ message: String, title: String, completion: (() -> Void)?)
    func exit()
}

protocol RecordHubViewOutput: class {
    func viewDidLoad()
    func viewWillDisapear()

    func vocalSliderValueChanged(value: Float)
    func musicSliderValueChanged(value: Float)

    func backButtonPressed()
    func recordButtonPressed()
    func undoPressed()
    func playButtonPressed()
    func rewindButtonPressed()
    func volumeButtonPressed()
    func shareButtonPressed()
}

final class RecordHubViewController: UIViewController {
    var viewModel: RecordHubViewModel
    var output: RecordHubViewOutput?
    var visualisationOutput: RecordHubVisualisationViewOutput?

    var needsUpdate: Bool = true

    // MARK: - Outlets

    @IBOutlet private var recordButton: UIButton!
    @IBOutlet private var shareButton: UIBarButtonItem!
    @IBOutlet private var playButton: UIButton!
    @IBOutlet private var rewindbutton: UIButton!
    @IBOutlet private var volumeButton: UIButton!
    @IBOutlet private var timerLabel: UILabel!
    @IBOutlet private var vocalVolumeSlider: UISlider!
    @IBOutlet private var musicVolumeSlider: UISlider!
    @IBOutlet private var controllsView: UIView!
    @IBOutlet private var musicLabel: UILabel!
    @IBOutlet private var vocalsLabel: UILabel!
    @IBOutlet private var volumePanelHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var undoButton: UIButton!
    @IBOutlet private weak var containerView: UIView!

    // MARK: - Lifecycle

    init(viewModel: RecordHubViewModel, output: RecordHubViewOutput) {
        self.viewModel = viewModel
        self.output = output
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        viewModel = RecordHubViewModel(state: RecordHubState(projectID: 0, takeID: 0))
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configView()
        output?.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showSpotlight()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        output?.viewWillDisapear()
    }

    // MARK: - Actions

    // MARK: - Sliders

    @IBAction private func vocalSliderValueChanged(_ sender: Any) {
        output?.vocalSliderValueChanged(value: vocalVolumeSlider.value)
    }

    @IBAction private func musicSliderValueChanged(_ sender: Any) {
        output?.musicSliderValueChanged(value: musicVolumeSlider.value)
    }

    // MARK: - Buttons

    @objc func backButtonPressed() {
        output?.backButtonPressed()
    }

    @IBAction private func recordButtonPressed(_ sender: Any) {
        output?.recordButtonPressed()
    }

    @IBAction func undoPressed(_ sender: Any) {
        output?.undoPressed()
    }

    @IBAction private func playButtonPressed(_ sender: Any) {
        output?.playButtonPressed()
    }

    @IBAction private func rewindButtonPressed(_ sender: Any) {
        output?.rewindButtonPressed()
    }

    @IBAction private func volumeButtonPressed(_ sender: Any) {
        output?.volumeButtonPressed()
    }

    @IBAction private func shareButtonPressed(_ sender: Any) {
        output?.shareButtonPressed()
    }

    // MARK: - Private

    func configView() {
        let device = Device.current
        if device.diagonal < 4.7 {
            timerLabel.font = timerLabel.font.withSize(29)
        }
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        recordButton.isHidden = false
//        self.shareButton.isEnabled = false

        let button = UIButton(type: .system)
        button.setImage(UIImage(imageLiteralResourceName: "BackButtonWhite"), for: .normal)
        button.setTitle(" Back", for: .normal)
        button.titleLabel?.font = button.titleLabel?.font.withSize(18.0)
        button.sizeToFit()
        button.addTarget(self, action: #selector(RecordHubViewController.backButtonPressed), for: .touchUpInside)
        let newBackButton = UIBarButtonItem(customView: button)

        navigationItem.leftBarButtonItem = newBackButton
    }

    func showPanel() {
        musicVolumeSlider.alpha = 0.0
        vocalVolumeSlider.alpha = 0.0
        vocalsLabel.alpha = 0.0
        musicLabel.alpha = 0.0
        musicVolumeSlider.isHidden = false
        vocalVolumeSlider.isHidden = false
        vocalsLabel.isHidden = false
        musicLabel.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.volumePanelHeightConstraint.constant = 130
            self.volumeButton.setImage(#imageLiteral(resourceName: "VolPanelOff"), for: .normal)
            self.musicVolumeSlider.alpha = 1.0
            self.vocalVolumeSlider.alpha = 1.0
            self.vocalsLabel.alpha = 1.0
            self.musicLabel.alpha = 1.0
            self.view.layoutIfNeeded()
        }
    }

    func hidePanel() {
        UIView.animate(withDuration: 0.3) {
            self.volumeButton.setImage(#imageLiteral(resourceName: "VolPanelOn"), for: .normal)
            self.musicVolumeSlider.alpha = 0.0
            self.vocalVolumeSlider.alpha = 0.0
            self.vocalsLabel.alpha = 0.0
            self.musicLabel.alpha = 0.0
            self.volumePanelHeightConstraint.constant = 0
            self.musicVolumeSlider.isHidden = false
            self.vocalVolumeSlider.isHidden = false
            self.vocalsLabel.isHidden = false
            self.musicLabel.isHidden = false
            self.view.layoutIfNeeded()
        }
    }

    func showHideVolumePanel(show: Bool) {
        show ? showPanel() : hidePanel()
    }

    private func lockInterface(_ isWorking: Bool) {
        shareButton.isEnabled = !isWorking
        playButton.isEnabled = !isWorking
        rewindbutton.isEnabled = !isWorking
    }

    private func showSpotlight() {
        let spotlightShown = UserDefaults.standard.bool(forKey: "RecordHubSpotlightIsShown")
        if !spotlightShown {
            configSpotlightView()
            UserDefaults.standard.set(true, forKey: "RecordHubSpotlightIsShown")
        }
    }

    private func configSpotlightView() {
        if let buttonView = recordButton,
            let navigation = self.navigationController,
            let navigationView = self.navigationController?.view {
            let navbarHeight = navigation.navigationBar.frame.height
            guard let buttonOrigin = buttonView.getGlobalPoint(toView: navigationView) else {
                return
            }
            let ycoord = buttonOrigin.y + navbarHeight + getStatusBarHeight()
            let xcoord = view.frame.width / 2 - buttonView.frame.height / 2
            let origin = CGPoint(x: xcoord, y: ycoord)
            let aRect = CGRect(origin: origin,
                               size: CGSize(width: buttonView.frame.height, height: buttonView.frame.height))
            let text = """
                When you're ready to record, just tap here!
            """
            let record = AwesomeSpotlight(withRect: aRect,
                                              shape: .circle,
                                              text: text,
                                              isAllowPassTouchesThroughSpotlight: false)

            let textLyrics = """
                To add lyrics, just tap the bottom half of the screen and start typiing!
            """
            guard let containerOrigin = containerView.getGlobalPoint(toView: navigationView) else {
                return
            }
            let ycoordLyrics = containerOrigin.y + 80.0
            let xcoordLyrics = CGFloat(5.0)
            let originLyrics = CGPoint(x: xcoordLyrics, y: ycoordLyrics)
            let lyricsRect = CGRect(origin: originLyrics,
                                    size: CGSize(width: view.frame.width - 5, height: 80))
            let lyrics = AwesomeSpotlight(withRect: lyricsRect,
                                          shape: .roundRectangle,
                                          text: textLyrics,
                                          isAllowPassTouchesThroughSpotlight: false)

            let textShare = """
                When you're done recording, tap the share symbol in the corner!
            """
            let ycoordShare = Device.current.isPad ? navbarHeight / 2 : navbarHeight
            let xcoordShare = navigation.navigationBar.frame.width - navbarHeight - 8
            let realOriginShare = CGPoint(x: xcoordShare, y: ycoordShare)
            let shareRect = CGRect(origin: realOriginShare,
                                   size: CGSize(width: navbarHeight, height: navbarHeight))
            let share = AwesomeSpotlight(withRect: shareRect,
                                          shape: .roundRectangle,
                                          text: textShare,
                                          isAllowPassTouchesThroughSpotlight: false)

            let spotlightView = AwesomeSpotlightView(frame: navigationView.frame, spotlight: [record, lyrics, share])
            spotlightView.spotlightMaskColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.9099361796)
            spotlightView.cutoutRadius = 8
            spotlightView.delegate = self
            navigationView.addSubview(spotlightView)
            spotlightView.start()
        }
    }
}

// MARK: - Segues

extension RecordHubViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "RecordHubPageViewController":
            guard let destination = segue.destination as? RecordHubPageViewController else {
                return
            }
            destination.projectID = viewModel.projectID
            destination.takeID = viewModel.takeID
        case "RecordHubVisualisationViewController":
            guard let destination = segue.destination as? RecordHubVisualisationViewController else {
                return
            }
            visualisationOutput?.input = destination
            destination.output = visualisationOutput
        default:
            break
        }
    }
}

// MARK: - RecordHubViewInput

extension RecordHubViewController: RecordHubViewInput, ViewUpdatable {
    func showMessage(_ message: String, title: String, completion: (() -> Void)? = nil) {
        showAlert(message: message, title: title, completion: completion)
    }

    func exit() {
        navigationController?.popViewController(animated: true)
    }

    func showError(_ error: Error) {
        showAlert(message: error.localizedDescription)
    }

    func presentView(view: UIViewController) {
        if let popoverController = view.popoverPresentationController {
            popoverController.barButtonItem = shareButton
            popoverController.sourceView = self.view
            popoverController.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        }
        present(view, animated: true)
    }

    func setNeedsUpdate() {
        needsUpdate = true
    }

    @discardableResult
    func update(with viewModel: RecordHubViewModel, animated: Bool) -> Bool {
        let oldViewModel = self.viewModel
        guard needsUpdate || viewModel != oldViewModel else {
            return false
        }
        self.viewModel = viewModel

        // update view
        update(new: viewModel, old: oldViewModel, keyPath: \.isMyTake) { isMyTake in
            self.recordButton.isHidden = !isMyTake
            self.navigationController?.navigationBar.topItem?.rightBarButtonItem?.isEnabled = isMyTake
        }

        update(new: viewModel, old: oldViewModel, keyPath: \.currentTimeString) { currentTimeString in
            self.timerLabel.text = currentTimeString
        }

        updateLoadingState(viewModel: viewModel, oldViewModel: oldViewModel, animated: animated)
        updateRenderingState(viewModel: viewModel, oldViewModel: oldViewModel, animated: animated)
        updateUploadingState(viewModel: viewModel, oldViewModel: oldViewModel, animated: animated)

        updateRenderingProgress(viewModel: viewModel, oldViewModel: oldViewModel, animated: animated)
        updateUploadingProgress(viewModel: viewModel, oldViewModel: oldViewModel, animated: animated)

        update(new: viewModel, old: oldViewModel, keyPath: \.isVolumePanelOpen) { isOpen in
            showHideVolumePanel(show: isOpen)
        }

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

    private func updateRenderingState(viewModel: RecordHubViewModel,
                                      oldViewModel: RecordHubViewModel,
                                      animated: Bool) {
        func showProgress(_ isRendering: Bool) {
            view.isUserInteractionEnabled = !isRendering
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

    private func updateRenderingProgress(viewModel: RecordHubViewModel,
                                         oldViewModel: RecordHubViewModel,
                                         animated: Bool) {
        update(new: viewModel, old: oldViewModel, keyPath: \.renderingProgress) { renderingProgress in
            updateRenderingHUD(withProgress: Float(renderingProgress))
        }
    }

    private func updateUploadingState(viewModel: RecordHubViewModel,
                                      oldViewModel: RecordHubViewModel,
                                      animated: Bool) {
        func showProgress(_ isUploading: Bool) {
            view.isUserInteractionEnabled = !isUploading
            if isUploading {
                showProgressHUD(animated: false)
            } else {
                hideProgressHUD(animated: false)
            }
        }

        update(new: viewModel, old: oldViewModel, keyPath: \.isUploading) { isUploading in
            lockInterface(isUploading)
            if isUploading {
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

    private func updateUploadingProgress(viewModel: RecordHubViewModel,
                                         oldViewModel: RecordHubViewModel,
                                         animated: Bool) {
        update(new: viewModel, old: oldViewModel, keyPath: \.uploadProgress) { uploadProgress in
            updateProgressHUD(withProgress: Float(uploadProgress))
        }
    }

    private func updateLoadingState(viewModel: RecordHubViewModel,
                                    oldViewModel: RecordHubViewModel,
                                    animated: Bool) {
        func showLoading(_ isLoading: Bool) {
            view.isUserInteractionEnabled = !isLoading
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

// MARK: - AwesomeSpotlightViewDelegate

extension RecordHubViewController: AwesomeSpotlightViewDelegate {
}
