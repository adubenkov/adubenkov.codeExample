//
//  Created by Andrey Dubenkov on 25/07/2019
//  Copyright © 2019 . All rights reserved.
//

import UIKit

protocol SubscriptionsViewInput: AnyObject {
    @discardableResult
    func update(with viewModel: SubscriptionsViewModel, animated: Bool) -> Bool
    func setNeedsUpdate()
}

protocol SubscriptionsViewOutput: AnyObject {
    func viewDidLoad()
    func closeEventTriggered()
    func selectionEventTriggered(with cellModel: SubscriptionCellModel)
    func buyingEventTriggered(with cellModel: SubscriptionCellModel?)
}

final class SubscriptionsViewController: UIViewController {
    private(set) var viewModel: SubscriptionsViewModel
    let output: SubscriptionsViewOutput

    var needsUpdate: Bool = true

    // MARK: - Subviews

    private lazy var policyButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(privacyPolicyButtonPressed), for: .touchUpInside)
        button.setTitle("Privacy policy", for: .normal)
        button.titleLabel?.textColor = .lightGray
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.titleLabel?.textAlignment = .center
//        button.backgroundColor = .red
        return button
    }()

    private lazy var termsButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(termsOfUsePressed), for: .touchUpInside)
        button.setTitle("Terms of Use", for: .normal)
        button.titleLabel?.textColor = .lightGray
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.titleLabel?.textAlignment = .center
//        button.backgroundColor = .red
        return button
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(#imageLiteral(resourceName: "BackButton"), for: .normal)
        button.setImage(#imageLiteral(resourceName: "BackButton").withAlphaComponent(0.5), for: .highlighted)
        button.contentVerticalAlignment = .center
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
        return button
    }()

    private lazy var backgroundImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "Subscriptions_bg")
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 25)
        label.textAlignment = .center
        return label
    }()

    private lazy var subTitleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 4
        return label
    }()

    private lazy var optionsLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .left
        label.textColor = .white
        label.font = .systemFont(ofSize: 20)
        label.textAlignment = .center
        return label
    }()

    private lazy var scrollView: UIScrollView = .init()

    private lazy var scrollContainerView: UIView = .init()

    private lazy var buttonsContainerView: UIView = .init()

    private lazy var headerContainerView: UIView = .init()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.indicatorStyle = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    private lazy var buyButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .brandBlue
        button.setTitle("SUBMIT", for: .normal)
        button.addTarget(self, action: #selector(buyButtonPressed), for: .touchUpInside)
        button.layer.cornerRadius = 25
        button.tag = 357
        return button
    }()

    private lazy var logoImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(imageLiteralResourceName: "Logo")
        return imageView
    }()

    private lazy var subscriptionSizeCell: SubscriptionCollectionViewCell = .init()
    private lazy var subscriptionMiniSizeCell: SubscriptionMiniCollectionViewCell = .init()

    // MARK: - Lifecycle

    init(viewModel: SubscriptionsViewModel, output: SubscriptionsViewOutput) {
        self.viewModel = viewModel
        self.output = output
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        disableAutomaticContentInsetsAdjustment(for: collectionView)
        collectionView.register(
            SubscriptionCollectionViewCell.self,
            forCellWithReuseIdentifier: SubscriptionCollectionViewCell.reuseID
        )
        collectionView.register(
            SubscriptionMiniCollectionViewCell.self,
            forCellWithReuseIdentifier: SubscriptionMiniCollectionViewCell.reuseID
        )

        view.addSubviews(
            backgroundImage,
            scrollView
        )

        scrollView.addSubviews(
            scrollContainerView
        )

        scrollContainerView.addSubviews(
            headerContainerView,
            collectionView,
            buyButton
        )

        buttonsContainerView.addSubviews(
            policyButton,
            termsButton
        )

        headerContainerView.addSubviews(
            logoImage,
            closeButton,
            titleLabel,
            subTitleLabel,
            optionsLabel,
            buttonsContainerView
        )

        output.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Layout

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        backgroundImage.configureFrame { maker in
            maker.top()
            maker.left(to: view.nui_left)
            maker.right(to: view.nui_right)
            maker.bottom(to: view.nui_bottom)
        }

        scrollView.configureFrame { maker in
            maker.top(inset: safeAreaInsets.top)
            maker.bottom(to: view.nui_bottom)
            maker.left(to: view.nui_left)
            maker.right(to: view.nui_right)
        }

        scrollContainerView.configureFrame { maker in
            maker.top(to: scrollView.nui_top)
            maker.left(to: scrollView.nui_left)
            maker.right(to: scrollView.nui_right)
            maker.height(viewModel.scrollViewHeight)
        }

        scrollView.contentSize = scrollContainerView.bounds.size
        layoutButtonsSection()
        layoutHeaderSection()

        collectionView.configureFrame { maker in
            maker.top(to: headerContainerView.nui_bottom)
            maker.bottom(to: buyButton.nui_top)
            maker.left(to: scrollContainerView.nui_left)
            maker.right(to: scrollContainerView.nui_right)
        }

        collectionView.scrollIndicatorInsets = collectionView.contentInset

        buyButton.configureFrame { maker in
            maker.centerX(to: scrollContainerView.nui_centerX)
            maker.bottom(to: scrollContainerView.nui_bottom, inset: 40)
            maker.size(width: 200, height: 50)
        }
    }

    private func layoutButtonsSection() {
        policyButton.configureFrame { maker in
            maker.centerY(to: buttonsContainerView.nui_centerY)
            maker.top(to: buttonsContainerView.nui_top)
            maker.left(to: buttonsContainerView.nui_left, inset: 100)
            maker.size(width: 100, height: 20)
        }
        termsButton.configureFrame { maker in
            maker.centerY(to: buttonsContainerView.nui_centerY)
            maker.top(to: buttonsContainerView.nui_bottom)
            maker.right(to: buttonsContainerView.nui_right, inset: 100)
            maker.size(width: 100, height: 20)
        }

        buttonsContainerView.configureFrame { maker in
            maker.bottom(to: collectionView.nui_bottom, inset: 20)
            maker.width(200)
            maker.height(20)
            maker.left(to: headerContainerView.nui_left)
            maker.right(to: headerContainerView.nui_right)
        }
    }

    private func layoutHeaderSection() {
        logoImage.configureFrame { maker in
            maker.centerX(to: headerContainerView.nui_centerX)
            maker.top(to: headerContainerView.nui_top, inset: 60)
            maker.size(width: 139, height: 139)
        }

        closeButton.configureFrame { maker in
            maker.top(to: headerContainerView.nui_top, inset: safeAreaInsets.top)
            maker.left(to: headerContainerView.nui_left, inset: 20)
            maker.size(width: 50, height: 30)
        }

        titleLabel.configureFrame { maker in
            maker.sizeToFit()
            maker.top(to: logoImage.nui_bottom, inset: 35)
            maker.left(to: headerContainerView.nui_left, inset: 0)
            maker.right(to: headerContainerView.nui_right, inset: 0)
        }

        subTitleLabel.configureFrame { maker in
            maker.top(to: titleLabel.nui_bottom, inset: 15)
            maker.left(to: headerContainerView.nui_left, inset: 37)
            maker.right(to: headerContainerView.nui_right, inset: 37)
            maker.sizeToFit()
        }

        optionsLabel.configureFrame { maker in
            maker.sizeToFit()
            maker.top(to: subTitleLabel.nui_bottom, inset: 15)
            maker.left(to: headerContainerView.nui_left, inset: 37)
            maker.right(to: headerContainerView.nui_right, inset: 37)
        }

        headerContainerView.configureFrame { maker in
            maker.height(viewModel.headerViewHeight)
            maker.top(to: scrollContainerView.nui_top)
            maker.left(to: scrollContainerView.nui_left)
            maker.right(to: scrollContainerView.nui_right)
        }
    }

    // MARK: - Actions

    @objc private func closeButtonPressed() {
        output.closeEventTriggered()
    }

    @objc private func buyButtonPressed() {
        let cellModel = viewModel.subscriptionsCellModels.filter {
            $0.isSelected == true
        }.first
        output.buyingEventTriggered(with: cellModel)
    }

    @objc private func privacyPolicyButtonPressed() {
        guard let url = URL(string: "https://rmusic.io/privacy.html") else {
            return
        }
        UIApplication.shared.open(url)
    }

    @objc private func termsOfUsePressed() {
        guard let url = URL(string: "https://rmusic.io/terms.html") else {
            return
        }
        UIApplication.shared.open(url)
    }
}

// MARK: - SubscriptionsViewInput

extension SubscriptionsViewController: SubscriptionsViewInput, ViewUpdatable {
    func setNeedsUpdate() {
        needsUpdate = true
    }

    @discardableResult
    func update(with viewModel: SubscriptionsViewModel, animated: Bool) -> Bool {
        let oldViewModel = self.viewModel
        guard needsUpdate || viewModel != oldViewModel else {
            return false
        }
        self.viewModel = viewModel

        // update view

        updateLoadingState(viewModel: viewModel, oldViewModel: oldViewModel, animated: animated)
        updateLitterals(viewModel: viewModel, oldViewModel: oldViewModel, animated: animated)

        update(new: viewModel, old: oldViewModel, keyPath: \.cellType) { _ in
            if animated {
                collectionView.reloadData()
            } else {
                UIView.performWithoutAnimation {
                    self.collectionView.reloadData()
                }
            }
        }

        update(new: viewModel, old: oldViewModel, keyPath: \.subscriptionsCellModels) { _ in
            if animated {
                collectionView.performBatchUpdates({
                    collectionView.reloadSections(IndexSet(integer: 0))
                })
            } else {
                UIView.performWithoutAnimation {
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                }
            }
        }

        var needsLayout = false

        update(new: viewModel, old: oldViewModel, keyPath: \.shouldRemoveSecondLabel) { foo in
            if let viewWithTag = self.scrollContainerView.viewWithTag(357), foo {
                viewWithTag.removeFromSuperview()
            }
            needsLayout = true
        }

        update(new: viewModel, old: oldViewModel, keyPath: \.headerViewHeight) { height in
            self.headerContainerView.configureFrame { maker in
                maker.height(height)
            }
            needsLayout = true
        }

        update(new: viewModel, old: oldViewModel, keyPath: \.scrollViewHeight) { height in
            scrollContainerView.configureFrame { maker in
                maker.height(height)
            }
            needsLayout = true
        }

        if needsLayout {
            view.layout()
        }

        needsUpdate = false

        return true
    }

    private func updateLitterals(viewModel: SubscriptionsViewModel,
                                 oldViewModel: SubscriptionsViewModel,
                                 animated: Bool) {
        var needsLayout = false

        update(new: viewModel, old: oldViewModel, keyPath: \.title) { title in
            titleLabel.text = title
            needsLayout = true
        }

        update(new: viewModel, old: oldViewModel, keyPath: \.subTitle) { title in
            subTitleLabel.text = title
            needsLayout = true
        }

        update(new: viewModel, old: oldViewModel, keyPath: \.optionsTitle) { title in
            optionsLabel.text = title
            needsLayout = true
        }

        if needsLayout {
            view.layout()
        }
    }

    private func updateLoadingState(viewModel: SubscriptionsViewModel,
                                    oldViewModel: SubscriptionsViewModel,
                                    animated: Bool) {
        func showLoading(_ isLoading: Bool) {
            view.isUserInteractionEnabled = !isLoading
            collectionView.alpha = isLoading ? 0 : 1
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
}

// MARK: - UICollectionViewDataSource

extension SubscriptionsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return viewModel.subscriptionsCellModels.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch viewModel.cellType {
        case .mini:
            let reuseID = SubscriptionMiniCollectionViewCell.reuseID
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: reuseID,
                for: indexPath
            )
            if let cell = cell as? SubscriptionMiniCollectionViewCell,
                let cellModel = viewModel.subscriptionsCellModels[safe: indexPath.item] {
                cell.configure(with: cellModel)

                cell.selectActionHandler = { [weak output] in
                    output?.selectionEventTriggered(with: cellModel)
                }
            }
            return cell
        case .full:
            let reuseID = SubscriptionCollectionViewCell.reuseID
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: reuseID,
                for: indexPath
            )
            if let cell = cell as? SubscriptionCollectionViewCell,
                let cellModel = viewModel.subscriptionsCellModels[safe: indexPath.item] {
                cell.configure(with: cellModel)

                cell.selectActionHandler = { [weak output] in
                    output?.selectionEventTriggered(with: cellModel)
                }
            }
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        if let cellModel = viewModel.subscriptionsCellModels[safe: indexPath.item] {
            output.selectionEventTriggered(with: cellModel)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SubscriptionsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let cellModel = viewModel.subscriptionsCellModels[safe: indexPath.item] else {
            return .zero
        }
        // Size cell is not a part of collection view
        // It needed because collection view asks size before `collectionView:cellForItemAt:` call,
        // and cell is not accessible yet

        switch viewModel.cellType {
        case .mini:
            let sizeCell = subscriptionMiniSizeCell
            sizeCell.configure(with: cellModel)
            let fitSize = CGSize(width: collectionView.bounds.width, height: .greatestFiniteMagnitude)
            return sizeCell.sizeThatFits(fitSize)

        case .full:
            let sizeCell = subscriptionSizeCell
            sizeCell.configure(with: cellModel)
            let fitSize = CGSize(width: collectionView.bounds.width, height: .greatestFiniteMagnitude)
            return sizeCell.sizeThatFits(fitSize)
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12.0
    }
}
