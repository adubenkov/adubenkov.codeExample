//
//  SubscriptionMiniCollectionViewCell.swift
//  
//
//  Created by Andrey Dubenkov on 25/07/2019.
//  Copyright © 2019 . All rights reserved.
//

import Framezilla
import UIKit

final class SubscriptionMiniCollectionViewCell: UICollectionViewCell {
    typealias CellModel = SubscriptionCellModel
    typealias ActionHandler = () -> Void

    private enum Constants {
        static let insets: UIEdgeInsets = .init(top: 0, left: 40, bottom: 0, right: 40)
        static let innerInset: CGFloat = 6
        static let containerViewSize: CGSize = .init(width: 330, height: 53)
    }

    static var reuseID: String {
        return String(describing: self)
    }

    private var cellModel: CellModel?

    var selectActionHandler: ActionHandler?

    // MARK: - Subviews

    private lazy var subscriptionNameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .left
        label.textColor = .white
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .left
        return label
    }()

    private lazy var infoView: UIView = {
        let infoView = UIView(frame: .zero)
        infoView.borderWidth = 1.0
        infoView.borderColor = .lightGray
        infoView.layer.cornerRadius = 16
        infoView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        return infoView
    }()

    private lazy var priceLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .left
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        return label
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .subscriptionsGray
        view.borderWidth = 1.0
        view.borderColor = .lightGray
        view.layer.cornerRadius = 16
        return view
    }()

    // MARK: - Lifecycle

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubviews(
            containerView
        )

        containerView.addSubviews(
            subscriptionNameLabel,
            infoView
        )

        infoView.addSubview(priceLabel)
    }

    func configure(with cellModel: CellModel) {
        self.cellModel = cellModel
        configureCell(with: cellModel)
        layout()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        let insets = Constants.insets

        containerView.configureFrame { maker in
            maker.top(inset: 0)
            maker.bottom(to: contentView.nui_bottom)
            maker.left(to: contentView.nui_left, inset: insets.left)
            maker.right(to: contentView.nui_right, inset: insets.right)
        }

        layoutContainerView()
    }

    func layoutContainerView() {
        subscriptionNameLabel.configureFrame { maker in
            maker.centerY()
            maker.left(to: containerView.nui_left, inset: 12)
            maker.heightToFit()
            maker.width(160)
        }

        infoView.configureFrame { maker in
            maker.top(to: containerView.nui_top)
            maker.bottom(to: containerView.nui_bottom)
            maker.left(to: subscriptionNameLabel.nui_right, inset: 8)
            maker.right(to: containerView.nui_right)
        }

        priceLabel.configureFrame { maker in
            maker.top(to: infoView.nui_top)
            maker.bottom(to: infoView.nui_bottom)
            maker.left(to: infoView.nui_left)
            maker.right(to: infoView.nui_right)
        }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let insets = Constants.insets
        let innerInset = Constants.innerInset

        var height = insets.top

        let containerViewSize = Constants.containerViewSize
        height += containerViewSize.height + innerInset

        return CGSize(width: size.width, height: min(size.height, height))
    }

    // MARK: - Private

    private func configureCell(with cellModel: CellModel) {
        subscriptionNameLabel.text = cellModel.subscriptionName
        priceLabel.text = cellModel.price
        if cellModel.isSelected {
            infoView.backgroundColor = .subscriptionsGreen
        }
    }
}
