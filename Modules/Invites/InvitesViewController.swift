//
//  Created by Andrey Dubenkov on 26/06/2019
//  Copyright © 2019 . All rights reserved.
//

import Framezilla
import UIKit

protocol InvitesViewInput: AnyObject {
    @discardableResult
    func update(with viewModel: InvitesViewModel, animated: Bool) -> Bool
    func setNeedsUpdate()
}

protocol InvitesViewOutput: AnyObject {
    func viewDidLoad()
    func menuEventTriggered()
    func dataSourceChangeEventTriggered()
    func acceptEventTriggered(with inviteID: Int)
    func declineEventTriggered(with inviteID: Int)
    func resendEventTriggered(with inviteID: Int)
    func playbackEventTriggered(with inviteID: Int)
}

final class InvitesViewController: UIViewController {
    private(set) var viewModel: InvitesViewModel
    let output: InvitesViewOutput

    var needsUpdate: Bool = true

    // MARK: - Subviews

    private lazy var menuButton: UIBarButtonItem = .init(
        image: #imageLiteral(resourceName: "SandwitchButton"),
        style: .plain,
        target: self,
        action: #selector(menuButtonPressed)
    )

    private lazy var invitesSegmentControl: UISegmentedControl = {
        let segmentControl = UISegmentedControl()
        segmentControl.addTarget(self, action: #selector(invitesSegmentControlValueChanged), for: .valueChanged)
        if #available(iOS 13.0, *) {
            segmentControl.backgroundColor = UIColor.black
            segmentControl.layer.borderColor = UIColor.white.cgColor
            segmentControl.selectedSegmentTintColor = UIColor.white
            segmentControl.layer.borderWidth = 1

            let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            segmentControl.setTitleTextAttributes(titleTextAttributes, for: .normal)

            let titleTextAttributes1 = [NSAttributedString.Key.foregroundColor: UIColor.black]
            segmentControl.setTitleTextAttributes(titleTextAttributes1, for: .selected)
        } else {
            segmentControl.backgroundColor = .white
            segmentControl.tintColor = .brandBlue
        }
        return segmentControl
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.indicatorStyle = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    private lazy var noInvitesLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.text = "No invites"
        return label
    }()

    private lazy var inviteSizeCell: InviteCollectionViewCell = .init()

    // MARK: - Lifecycle

    init(viewModel: InvitesViewModel, output: InvitesViewOutput) {
        self.viewModel = viewModel
        self.output = output
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = menuButton
        view.backgroundColor = .black

        disableAutomaticContentInsetsAdjustment(for: collectionView)
        collectionView.register(
            InviteCollectionViewCell.self,
            forCellWithReuseIdentifier: InviteCollectionViewCell.reuseID
        )

        view.addSubviews(
            collectionView,
            invitesSegmentControl,
            noInvitesLabel
        )

        output.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isTranslucent = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isTranslucent = true
    }

    // MARK: - Layout

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        collectionView.configureFrame { maker in
            maker.edges(insets: .zero)
        }

        invitesSegmentControl.configureFrame { maker in
            maker.top(inset: safeAreaInsets.top + 16).centerX()
            maker.sizeToFit()
        }
        invitesSegmentControl.roundCorners(radius: 6)

        collectionView.contentInset.top = invitesSegmentControl.frame.maxY + 8
        collectionView.contentInset.bottom = safeAreaInsets.bottom + 16
        collectionView.scrollIndicatorInsets = collectionView.contentInset

        noInvitesLabel.configureFrame { maker in
            maker.center().sizeToFit()
        }
    }

    // MARK: - Actions

    @objc private func invitesSegmentControlValueChanged() {
        output.dataSourceChangeEventTriggered()
    }

    @objc private func menuButtonPressed() {
        output.menuEventTriggered()
    }
}

// MARK: - InvitesViewInput

extension InvitesViewController: InvitesViewInput, ViewUpdatable {
    func setNeedsUpdate() {
        needsUpdate = true
    }

    @discardableResult
    func update(with viewModel: InvitesViewModel, animated: Bool) -> Bool {
        let oldViewModel = self.viewModel
        guard needsUpdate || viewModel != oldViewModel else {
            return false
        }
        self.viewModel = viewModel

        updateLoadingState(oldViewModel: oldViewModel, newViewModel: viewModel, animated: true)
        updateInvitesSegmentControl(oldViewModel: oldViewModel, newViewModel: viewModel, animated: animated)

        update(new: viewModel, old: oldViewModel, keyPath: \.inviteCellModels) { cellModels in
            noInvitesLabel.isHidden = true
            if animated {
                collectionView.performBatchUpdates({
                    collectionView.reloadSections(IndexSet(integer: 0))
                }, completion: { _ in
                    self.noInvitesLabel.isHidden = !cellModels.isEmpty
                })
            } else {
                UIView.performWithoutAnimation {
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                }
                noInvitesLabel.isHidden = !cellModels.isEmpty
            }
        }

        update(new: viewModel, old: oldViewModel, keyPath: \.isAcceptingInvite) { isAccepting in
            guard !viewModel.isLoading else {
                return
            }
            if isAccepting {
                showLoadingHUD(animated: false)
            } else {
                hideLoadingHUD(animated: false)
            }
        }

        update(new: viewModel, old: oldViewModel, keyPath: \.isDecliningInvite) { isAccepting in
            guard !viewModel.isLoading else {
                return
            }
            if isAccepting {
                showLoadingHUD(animated: false)
            } else {
                hideLoadingHUD(animated: false)
            }
        }

        update(new: viewModel, old: oldViewModel, keyPath: \.isResendingInvite) { isResending in
            guard !viewModel.isLoading else {
                return
            }
            if isResending {
                showLoadingHUD(animated: false)
            } else {
                hideLoadingHUD(animated: false)
            }
        }

        view.layout()
        needsUpdate = false

        return true
    }

    private func updateInvitesSegmentControl(oldViewModel: InvitesViewModel,
                                             newViewModel: InvitesViewModel,
                                             animated: Bool) {
        update(new: newViewModel, old: oldViewModel, keyPath: \.invitesSegmentControlItems) { items in
            invitesSegmentControl.removeAllSegments()
            for index in 0 ..< items.count {
                invitesSegmentControl.insertSegment(withTitle: items[index], at: index, animated: false)
            }
        }
        update(new: newViewModel, old: oldViewModel, keyPath: \.invitesSegmentControlSelectedItemIndex) { index in
            invitesSegmentControl.selectedSegmentIndex = index
        }
    }

    private func updateLoadingState(oldViewModel: InvitesViewModel,
                                    newViewModel: InvitesViewModel,
                                    animated: Bool) {
        func showLoading(_ isLoading: Bool) {
            view.isUserInteractionEnabled = !isLoading
            collectionView.alpha = isLoading ? 0 : 1
            invitesSegmentControl.alpha = isLoading ? 0 : 1
            if isLoading {
                noInvitesLabel.isHidden = true
                showLoadingHUD(animated: false)
            } else {
                hideLoadingHUD(animated: false)
            }
        }

        update(new: newViewModel, old: oldViewModel, keyPath: \.isLoading) { isLoading in
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

// MARK: - UICollectionViewDataSource

extension InvitesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.inviteCellModels.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: InviteCollectionViewCell.reuseID,
            for: indexPath
        )

        if let cell = cell as? InviteCollectionViewCell,
            let cellModel = viewModel.inviteCellModels[safe: indexPath.item] {
            cell.configure(with: cellModel)
            cell.playbackActionHandler = { [weak output] in
                output?.playbackEventTriggered(with: cellModel.inviteID)
            }
            cell.acceptActionHandler = { [weak output] in
                output?.acceptEventTriggered(with: cellModel.inviteID)
            }
            cell.resendActionHandler = { [weak output] in
                output?.resendEventTriggered(with: cellModel.inviteID)
            }
            cell.declineActionHandler = { [weak output] in
                output?.declineEventTriggered(with: cellModel.inviteID)
            }
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension InvitesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let cellModel = viewModel.inviteCellModels[safe: indexPath.item] else {
            return .zero
        }
        // Size cell is not a part of collection view
        // It needed because collection view asks size before `collectionView:cellForItemAt:` call,
        // and cell is not accessible yet
        let sizeCell = inviteSizeCell
        sizeCell.configure(with: cellModel)
        let fitSize = CGSize(width: collectionView.bounds.width, height: .greatestFiniteMagnitude)
        return sizeCell.sizeThatFits(fitSize)
    }
}
