//
//  Created by Andrey Dubenkov on 10/11/2019
//  Copyright © 2019 . All rights reserved.
//

import DeviceKit
import UIKit

enum PlayButtonState: String {
    case playButton = "PlayButton"
    case pauseButton = "PauseButton"
}

protocol ProjectHubViewInput: class {
    @discardableResult
    func update(with viewModel: ProjectHubViewModel, animated: Bool) -> Bool
    func setNeedsUpdate()
    func showDialog(_ dialog: UIAlertController)
    func showError(_ error: Error)
    func showMessage(_ message: String, title: String, completion: (() -> Void)?)
    func exit()
}

protocol ProjectHubViewOutput: class {
    func viewDidLoad()
    func viewWillAppear()
    func viewWillDisapear()
    func playButtonPressed()
    func rewindButtonPressed()
    func volumeButtonPressed()
    func backButtonPressed()
    func newButtonPressed()
    func vocalSliderValueChanged(value: Float)
    func musicSliderValueChanged(value: Float)
}

final class ProjectHubViewController: UIViewController {
    var viewModel: ProjectHubViewModel
    var output: ProjectHubViewOutput?
    var visualisationOutput: ProjectHubVisualisationViewOutput?

    var needsUpdate: Bool = true

    // MARK: - Outlets

    @IBOutlet private var playButton: UIButton!
    @IBOutlet private var rewindbutton: UIButton!
    @IBOutlet private var volumeButton: UIButton!

    @IBOutlet private var newButton: UIButton!
    @IBOutlet private var timerLabel: UILabel!
    @IBOutlet private var vocalVolumeSlider: UISlider!
    @IBOutlet private var musicVolumeSlider: UISlider!
    @IBOutlet private var controllsView: UIView!
    @IBOutlet private var musicLabel: UILabel!
    @IBOutlet private var vocalsLabel: UILabel!
    @IBOutlet private var volumePanelHeightConstraint: NSLayoutConstraint!
    @IBOutlet var bottomContainer: UIView!

    // MARK: - Lifecycle

    required init?(coder aDecoder: NSCoder) {
        viewModel = ProjectHubViewModel(state: ProjectHubState(projectID: 0, scenario: .noOptions))
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configView()
        output?.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        output?.viewWillAppear()
        showSpotlight()
    }

    override func viewWillDisappear(_ animated: Bool) {
        output?.viewWillDisapear()
        super.viewWillDisappear(animated)
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

    @IBAction private func newButtonPressed(_ sender: Any) {
        output?.newButtonPressed()
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

    @objc func backButtonPressed() {
        output?.backButtonPressed()
    }

    // MARK: - Private

    func configView() {
        let device = Device.current
        if device.diagonal < 4.7 {
            timerLabel.font = timerLabel.font.withSize(29)
        }
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false

        let viewControllers = navigationController?.viewControllers
        // Replace navigation item title
        viewControllers?.first?.navigationItem.title = "Projects"
        let button = UIButton(type: .system)
        button.setImage(UIImage(imageLiteralResourceName: "BackButtonWhite"), for: .normal)
        button.setTitle(" Back", for: .normal)
        button.titleLabel?.font = button.titleLabel?.font.withSize(18.0)
        button.sizeToFit()
        button.addTarget(self, action: #selector(RecordHubViewController.backButtonPressed), for: .touchUpInside)
        let newBackButton = UIBarButtonItem(customView: button)

        navigationItem.leftBarButtonItem = newBackButton
    }

    private func showPanel() {
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
            self.volumeButton.setImage(UIImage(named: "VolPanelOff"), for: .normal)
            self.musicVolumeSlider.alpha = 1.0
            self.vocalVolumeSlider.alpha = 1.0
            self.vocalsLabel.alpha = 1.0
            self.musicLabel.alpha = 1.0
            self.view.layoutIfNeeded()
        }
    }

    private func hidePanel() {
        UIView.animate(withDuration: 0.3) {
            self.volumeButton.setImage(UIImage(named: "VolPanelOn"), for: .normal)
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

    private func showHideVolumePanel(show: Bool) {
        show ? showPanel() : hidePanel()
    }
}

// MARK: - ProjectHubViewInput

extension ProjectHubViewController: ProjectHubViewInput, ViewUpdatable {
    func showMessage(_ message: String, title: String, completion: (() -> Void)?) {
        var actions: [UIAlertAction] = []
        if let completion = completion {
            let action = UIAlertAction(title: "OK", style: .default, handler: { _ in completion() })
            actions.append(action)
        }

        showAlert(title: title, message: message, actions: actions)
    }

    func exit() {
        navigationController?.popViewController(animated: true)
    }

    func showError(_ error: Error) {
        showAlert(message: error.localizedDescription)
    }

    func showDialog(_ dialog: UIAlertController) {
        present(dialog, animated: true, completion: nil)
    }

    func setNeedsUpdate() {
        needsUpdate = true
    }

    @discardableResult
    func update(with viewModel: ProjectHubViewModel, animated: Bool) -> Bool {
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

        update(new: viewModel, old: oldViewModel, keyPath: \.isVolumePanelOpen) { isOpen in
            showHideVolumePanel(show: isOpen)
        }

        update(new: viewModel, old: oldViewModel, keyPath: \.isPlaying) { isPlaying in
            let buttonState: PlayButtonState = isPlaying ? .pauseButton : .playButton
            self.playButton.setImage(UIImage(named: buttonState.rawValue), for: .normal)
        }
        view.layout()
        needsUpdate = false

        return true
    }

    private func updateLoadingState(viewModel: ProjectHubViewModel,
                                    oldViewModel: ProjectHubViewModel,
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

    private func showSpotlight() {
        let spotlightShown = UserDefaults.standard.bool(forKey: "ProjectHubSpotlightIsShown")
        if !spotlightShown {
            configSpotlightView()
            UserDefaults.standard.set(true, forKey: "ProjectHubSpotlightIsShown")
        }
    }

    private func configSpotlightView() {
        if let buttonView = newButton,
            let navigation = self.navigationController,
            let navigationView = self.navigationController?.view {
            let navbarHeight = Device.current.isPad ? navigation.navigationBar.frame.height / 2 : navigation.navigationBar.frame.height

            let ycoord = navbarHeight
            let xcoord = view.frame.width / 2 - 20
            let origin = CGPoint(x: xcoord, y: ycoord)
            let aRect = CGRect(origin: origin,
                               size: CGSize(width: buttonView.frame.height, height: buttonView.frame.height))
            let text = """
                Hit the red "R" button
                to start your new take!
            """
            let newtake = AwesomeSpotlight(withRect: aRect,
                                              shape: .circle,
                                              text: text,
                                              isAllowPassTouchesThroughSpotlight: true)

            let textInvite = """
                Invite anyone in your iOS contact list to collaborate, simply type their name into a box here!
            """
            guard let containerOrigin = bottomContainer.getGlobalPoint(toView: navigationView) else {
                return
            }
            let ycoordInvite = containerOrigin.y + navbarHeight + 60.0
            let xcoordInvite = CGFloat(5.0)
            let originInvite = CGPoint(x: xcoordInvite, y: ycoordInvite)
            let inviteRect = CGRect(origin: originInvite,
                                    size: CGSize(width: view.frame.width - 5, height: 60))
            let invite = AwesomeSpotlight(withRect: inviteRect,
                                          shape: .roundRectangle,
                                          text: textInvite,
                                          isAllowPassTouchesThroughSpotlight: true)

            let spotlightView = AwesomeSpotlightView(frame: navigationView.frame, spotlight: [newtake])
            if viewModel.isMyProject && viewModel.scenario == .noOptions {
                spotlightView.spotlightsArray.append(invite)
            }
            spotlightView.spotlightMaskColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.9099361796)

            spotlightView.cutoutRadius = 8
            spotlightView.delegate = self
            navigationView.addSubview(spotlightView)
            spotlightView.start()
        }
    }
}

// MARK: - AwesomeSpotlightViewDelegate

extension ProjectHubViewController: AwesomeSpotlightViewDelegate {
}

// MARK: - Segues

extension ProjectHubViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "ProjectHubBottomContainer":
            guard let destination = segue.destination as? PHTabBarViewController else {
                return
            }
            destination.projectID = viewModel.projectID

            switch viewModel.scenario {
            case .noOptions:
                break
            case .toComment:
                destination.activeCommand = .showMessage
            case let .toInvite(userID):
                destination.activeCommand = .showInvite(id: userID)
            case let .toUserTakes(id):
                destination.activeCommand = .showUser(id: id)
            case .none:
                break
            }
        case "ProjectHubVisualisationViewController":
            guard let destination = segue.destination as? ProjectHubVisualisationViewController else {
                return
            }
            visualisationOutput?.input = destination
            destination.output = visualisationOutput
        default:
            break
        }
    }
}
