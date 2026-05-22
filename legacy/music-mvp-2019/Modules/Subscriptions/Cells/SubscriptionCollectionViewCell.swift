//
//  SubscriptionsCollectionViewCell.swift
//  
//
//  Created by Andrey Dubenkov on 25/07/2019.
//  Copyright © 2019 . All rights reserved.
//

import Framezilla
import UIKit

final class SubscriptionCollectionViewCell: UICollectionViewCell {
    typealias CellModel = SubscriptionCellModel
    typealias ActionHandler = () -> Void

    private enum Constants {
        static let insets: UIEdgeInsets = .init(top: 0, left: 40, bottom: 0, right: 40)
        static let innerInset: CGFloat = 6
        static let containerViewSize: CGSize = .init(width: 330, height: 142)
        static let checkBoxSize = CGSize(width: 22, height: 22)
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
        label.font = .systemFont(ofSize: 24.0)
        label.textAlignment = .center
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .center
        label.textColor = .lightGray
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        return label
    }()

    private lazy var priceLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .left
        label.textColor = .white
        label.font = .systemFont(ofSize: 22)
        return label
    }()

    private lazy var checkBoxImageView: UIImageView = {
        let checkBoxImageView = UIImageView()
        checkBoxImageView.image = UIImage(imageLiteralResourceName: "CheckBox")
        return checkBoxImageView
    }()

    private lazy var priceView: UIView = .init(frame: .zero)

    private lazy var containerView: UIView = .init(frame: .zero)

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
            descriptionLabel,
            priceView
        )

        priceView.addSubviews(
            priceLabel,
            checkBoxImageView
        )
    }

    func configure(with cellModel: CellModel) {
        self.cellModel = cellModel
        configureCell(with: cellModel)
        layout()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.configureFrame { maker in
            maker.edges(insets: Constants.insets)
        }

        layoutContainerView()
    }

    func layoutContainerView() {
        let innerInset = Constants.innerInset

        subscriptionNameLabel.configureFrame { maker in
            maker.centerX()
            maker.top(inset: 10)
            maker.sizeToFit()
        }

        descriptionLabel.configureFrame { maker in
            maker.top(to: subscriptionNameLabel.nui_bottom, inset: innerInset)
            maker.left(to: containerView.nui_left, inset: 21)
            maker.right(to: containerView.nui_right, inset: 21)
            maker.heightToFit()
        }

        priceView.configureFrame { maker in
            maker.top(to: descriptionLabel.nui_bottom)
            maker.bottom(to: containerView.nui_bottom)
            maker.left().right()
        }

        priceLabel.configureFrame { maker in
            maker.centerX(offset: -11)
            maker.centerY()
            maker.right(to: priceView.nui_right, inset: innerInset)
            maker.sizeToFit()
        }

        checkBoxImageView.configureFrame { maker in
            let innerInset = Constants.innerInset
            maker.size(CGSize(width: 22, height: 22))
            maker.centerY(to: priceLabel.nui_centerY)
            maker.right(to: priceLabel.nui_left, inset: innerInset)
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
        descriptionLabel.text = cellModel.subDescription
        containerView.layer.cornerRadius = 16
        if cellModel.isSelected {
            containerView.backgroundColor = .subscriptionsGray
            containerView.borderWidth = 1.0
            containerView.borderColor = .lightGray
            checkBoxImageView.image = UIImage(imageLiteralResourceName: "CheckBoxSelected")
        } else {
            containerView.backgroundColor = .clear
            containerView.borderWidth = 0.0
            checkBoxImageView.image = UIImage(imageLiteralResourceName: "CheckBox")
        }
    }
}
