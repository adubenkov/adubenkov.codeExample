//
//  InviteCollectionViewCell.swift
//  
//
//  Created by Andrey Dubenkov on 26/06/2019.
//  Copyright © 2019 . All rights reserved.
//

import AlamofireImage
import Framezilla
import UIKit

final class InviteCollectionViewCell: UICollectionViewCell {
    typealias CellModel = InviteCellModel
    typealias ActionHandler = () -> Void

    private enum Constants {
        static let insets: UIEdgeInsets = .init(top: 16, left: 24, bottom: 24, right: 24)
        static let collaboratorPhotoSize: CGSize = .init(width: 44, height: 44)
        static let innerInset: CGFloat = 16
        static let detailsSectionInnerInset: CGFloat = 4
        static let projectInfoSectionInnerInset: CGFloat = 8
        static let buttonsTopInset: CGFloat = 24
        static let playbackButtonSize = CGSize(width: 44, height: 44)
        static let acceptActionButtonSize = CGSize(width: 90, height: 32)
        static let declineActionButtonSize = CGSize(width: 90, height: 32)
    }

    static var reuseID: String {
        return String(describing: self)
    }

    private(set) var cellModel: CellModel?

    var playbackActionHandler: ActionHandler?
    var acceptActionHandler: ActionHandler?
    var declineActionHandler: ActionHandler?
    var resendActionHandler: ActionHandler?

    // MARK: - Subviews

    private lazy var collaboratorPhotoImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.image = #imageLiteral(resourceName: "Avatar Placeholder")
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private lazy var inviteTitleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .left
        label.textColor = .white
        label.font = .systemFont(ofSize: 17)
        return label
    }()

    private lazy var inviteDateLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = .lightGray
        return label
    }()

    private lazy var detailsContainerView: UIView = .init(frame: .zero)

    private lazy var projectNameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .left
        return label
    }()

    private lazy var projectTimeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .left
        return label
    }()

    private lazy var projectTempoLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .left
        return label
    }()

    private lazy var projectKeyLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .left
        return label
    }()

    private lazy var projectNoteLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .left
        return label
    }()

    private lazy var inviteStatusLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .left
        return label
    }()

    private lazy var playbackButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = #imageLiteral(resourceName: "PlayButton")
        button.setImage(image, for: .normal)
        button.setImage(image.withAlphaComponent(0.5), for: .highlighted)
        button.addTarget(self, action: #selector(playbackButtonPressed), for: .touchUpInside)
        return button
    }()

    private lazy var trackLoadingIndicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .white)
        indicatorView.hidesWhenStopped = true
        return indicatorView
    }()

    private lazy var resendInviteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .brandBlue
        button.setImage(#imageLiteral(resourceName: "Resend").masked(using: .white), for: .normal)
        button.setImage(#imageLiteral(resourceName: "Resend").masked(using: UIColor.white.withAlphaComponent(0.5)), for: .highlighted)
        button.addTarget(self, action: #selector(resendInviteButtonPressed), for: .touchUpInside)
        return button
    }()

    private lazy var acceptInviteButton: UIButton = {
        let button = UIButton(type: .custom)
        let normalAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white]
        let highlightedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.5)
        ]
        button.setAttributedTitle(NSAttributedString(string: "Accept", attributes: normalAttributes), for: .normal)
        button.setAttributedTitle(NSAttributedString(string: "Accept", attributes: highlightedAttributes),
                                  for: .highlighted)
        button.backgroundColor = .brandBlue
        button.addTarget(self, action: #selector(acceptInviteButtonPressed), for: .touchUpInside)
        return button
    }()

    private lazy var declineInviteButton: UIButton = {
        let button = UIButton(type: .custom)
        let normalAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white]
        let highlightedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.5)
        ]
        button.setAttributedTitle(NSAttributedString(string: "Decline", attributes: normalAttributes), for: .normal)
        button.setAttributedTitle(NSAttributedString(string: "Decline", attributes: highlightedAttributes),
                                  for: .highlighted)
        button.backgroundColor = .clear
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1

        button.addTarget(self, action: #selector(declineInviteButtonPressed), for: .touchUpInside)
        return button
    }()

    private lazy var separatorView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .darkGray
        return view
    }()

    // MARK: - Lifecycle

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        detailsContainerView.addSubviews(
            projectNameLabel,
            projectTimeLabel,
            projectTempoLabel,
            projectKeyLabel,
            projectNoteLabel,
            inviteStatusLabel
        )
        contentView.addSubviews(
            collaboratorPhotoImageView,
            inviteTitleLabel,
            inviteDateLabel,
            detailsContainerView,
            playbackButton,
            trackLoadingIndicatorView,
            resendInviteButton,
            acceptInviteButton,
            declineInviteButton,
            separatorView
        )
    }

    func configure(with cellModel: CellModel) {
        self.cellModel = cellModel

        collaboratorPhotoImageView.af_cancelImageRequest()
        if let photoURL = cellModel.collaboratorPhotoURL {
            collaboratorPhotoImageView.af_setImage(withURL: photoURL, placeholderImage: #imageLiteral(resourceName: "Avatar Placeholder"))
        } else {
            collaboratorPhotoImageView.image = #imageLiteral(resourceName: "Avatar Placeholder")
        }

        configureDetailsSection(with: cellModel)
        configureActionButtons(with: cellModel)

        layout()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        let insets = Constants.insets
        let innerInset = Constants.innerInset

        let collaboratorPhotoSize = Constants.collaboratorPhotoSize
        collaboratorPhotoImageView.configureFrame { maker in
            maker.left(inset: insets.left).top(inset: insets.top)
            maker.size(collaboratorPhotoSize)
        }
        collaboratorPhotoImageView.roundCorners(radius: collaboratorPhotoSize.height / 2)

        inviteDateLabel.configureFrame { maker in
            maker.centerY(to: collaboratorPhotoImageView.nui_centerY)
            maker.right(inset: insets.right)
            maker.sizeToFit()
        }
        inviteTitleLabel.configureFrame { maker in
            maker.right(to: inviteDateLabel.nui_left, inset: innerInset)
            maker.left(to: collaboratorPhotoImageView.nui_right, inset: innerInset)
            maker.centerY(to: collaboratorPhotoImageView.nui_centerY)
            maker.heightToFit()
        }

        layoutDetailsSection()
        layoutActionButtons()

        separatorView.configureFrame { maker in
            maker.left().right().bottom()
            maker.height(1)
        }
    }

    private func layoutDetailsSection() {
        detailsContainerView.configureFrame { maker in
            let inset = Constants.innerInset
            maker.top(to: collaboratorPhotoImageView.nui_bottom, inset: inset)
            maker.left(to: collaboratorPhotoImageView.nui_right, inset: inset)
            maker.right(to: inviteDateLabel.nui_left, inset: inset)
        }

        projectNameLabel.configureFrame { maker in
            maker.top().left().right().heightToFit()
        }

        let inset = Constants.detailsSectionInnerInset
        projectTimeLabel.configureFrame { maker in
            maker.top(to: projectNameLabel.nui_bottom, inset: inset)
            maker.left().right().heightToFit()
        }
        projectTempoLabel.configureFrame { maker in
            maker.top(to: projectTimeLabel.nui_bottom, inset: inset)
            maker.left().right().heightToFit()
        }
        projectKeyLabel.configureFrame { maker in
            maker.top(to: projectTempoLabel.nui_bottom, inset: inset)
            maker.left().right().heightToFit()
        }
        let isProjectNoteHidden = cellModel?.projectNote == nil
        projectNoteLabel.configureFrame { maker in
            maker.top(to: projectKeyLabel.nui_bottom, inset: isProjectNoteHidden ? 0 : inset)
            maker.left().right()
            if isProjectNoteHidden {
                maker.height(0)
            } else {
                maker.heightToFit()
            }
        }

        let isStatusHidden = cellModel?.inviteStatusString == nil
        inviteStatusLabel.configureFrame { maker in
            maker.top(to: projectNoteLabel.nui_bottom, inset: isStatusHidden ? 0 : inset)
            maker.left().right()
            if isStatusHidden {
                maker.height(0)
            } else {
                maker.heightToFit()
            }
        }
        detailsContainerView.configureFrame { maker in
            maker.height(inviteStatusLabel.frame.maxY)
        }
    }

    private func layoutActionButtons() {
        let inset = Constants.innerInset

        playbackButton.configureFrame { maker in
            maker.top(to: inviteStatusLabel.nui_bottom, inset: Constants.buttonsTopInset)
            maker.left(to: collaboratorPhotoImageView.nui_right, inset: inset)
            maker.size(Constants.playbackButtonSize)
        }
        trackLoadingIndicatorView.configureFrame { maker in
            maker.center(to: playbackButton)
            maker.sizeToFit()
        }

        acceptInviteButton.configureFrame { maker in
            maker.left(to: playbackButton.nui_right, inset: inset)
            maker.centerY(to: playbackButton.nui_centerY)
            maker.size(Constants.acceptActionButtonSize)
        }
        acceptInviteButton.roundCorners(radius: acceptInviteButton.bounds.height / 2)

        declineInviteButton.configureFrame { maker in
            maker.left(to: acceptInviteButton.nui_right, inset: inset)
            maker.centerY(to: playbackButton.nui_centerY)
            maker.size(Constants.declineActionButtonSize)
        }
        declineInviteButton.layer.cornerRadius = declineInviteButton.bounds.height / 2
        resendInviteButton.configureFrame { maker in
            maker.left(to: playbackButton.nui_right, inset: inset)
            maker.centerY(to: playbackButton.nui_centerY)
            maker.size(playbackButton.bounds.size)
        }
        resendInviteButton.roundCorners(radius: resendInviteButton.bounds.height / 2)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let cellModel = cellModel else {
            return .zero
        }

        let insets = Constants.insets
        let innerInset = Constants.innerInset

        var height = insets.top

        let collaboratorPhotoSize = Constants.collaboratorPhotoSize
        height += collaboratorPhotoSize.height + innerInset

        let inviteDateLabelSize = inviteDateLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                                      height: .greatestFiniteMagnitude))
        var detailsSectionWidth = size.width
        detailsSectionWidth -= insets.left + collaboratorPhotoSize.width + innerInset
        detailsSectionWidth -= inviteDateLabelSize.width + insets.right

        let detailsInnerInset = Constants.detailsSectionInnerInset
        let detailsSectionFitSize = CGSize(width: detailsSectionWidth, height: .greatestFiniteMagnitude)
        height += projectNameLabel.sizeThatFits(detailsSectionFitSize).height + detailsInnerInset
        height += projectTimeLabel.sizeThatFits(detailsSectionFitSize).height + detailsInnerInset
        height += projectTempoLabel.sizeThatFits(detailsSectionFitSize).height + detailsInnerInset
        height += projectKeyLabel.sizeThatFits(detailsSectionFitSize).height

        if cellModel.projectNote != nil {
            height += detailsInnerInset
            height += projectNoteLabel.sizeThatFits(detailsSectionFitSize).height
        }

        if cellModel.inviteStatusString != nil {
            height += detailsInnerInset
            height += inviteStatusLabel.sizeThatFits(detailsSectionFitSize).height
        }

        height += Constants.buttonsTopInset
        height += Constants.playbackButtonSize.height
        height += insets.bottom

        return CGSize(width: size.width, height: min(size.height, height))
    }

    // MARK: - Actions

    @objc private func playbackButtonPressed() {
        playbackActionHandler?()
    }

    @objc private func resendInviteButtonPressed() {
        resendActionHandler?()
    }

    @objc private func acceptInviteButtonPressed() {
        acceptActionHandler?()
    }

    @objc private func declineInviteButtonPressed() {
        declineActionHandler?()
    }

    // MARK: - Private

    private func configureDetailsSection(with cellModel: CellModel) {
        inviteTitleLabel.text = cellModel.inviteTitle
        inviteDateLabel.text = cellModel.inviteDateString

        projectNameLabel.attributedText = attributedString(
            withTitle: "Project",
            subtitle: cellModel.projectName
        )
        projectTimeLabel.attributedText = attributedString(
            withTitle: "Time",
            subtitle: cellModel.projectTimeString
        )
        projectTempoLabel.attributedText = attributedString(
            withTitle: "Tempo",
            subtitle: cellModel.projectTempoString
        )
        projectKeyLabel.attributedText = attributedString(
            withTitle: "Key",
            subtitle: cellModel.projectKeyString
        )

        if let projectNote = cellModel.projectNote {
            projectNoteLabel.attributedText = attributedString(
                withTitle: "Note",
                subtitle: projectNote
            )
        } else {
            projectNoteLabel.attributedText = nil
        }

        if let inviteStatusString = cellModel.inviteStatusString {
            inviteStatusLabel.attributedText = attributedString(
                withTitle: "Status",
                subtitle: inviteStatusString
            )
        } else {
            inviteStatusLabel.attributedText = nil
        }
    }

    private func configureActionButtons(with cellModel: CellModel) {
        acceptInviteButton.isHidden = cellModel.isInviteAcceptActionHidden
        declineInviteButton.isHidden = cellModel.isInviteDeclineActionHidden
        resendInviteButton.isHidden = cellModel.isInviteResendActionHidden

        if cellModel.isLoadingTrack {
            playbackButton.isHidden = true
            trackLoadingIndicatorView.startAnimating()
        } else {
            trackLoadingIndicatorView.stopAnimating()
            playbackButton.isHidden = false

            let playbackButtonImage: UIImage
            if cellModel.isPlayingTrack {
                playbackButtonImage = #imageLiteral(resourceName: "StopPlayback")
            } else {
                playbackButtonImage = #imageLiteral(resourceName: "PlayButton")
            }
            playbackButton.setImage(playbackButtonImage, for: .normal)
            playbackButton.setImage(playbackButtonImage.withAlphaComponent(0.5), for: .highlighted)
        }
    }

    private func attributedString(withTitle title: String, subtitle: String) -> NSAttributedString {
        if title.isEmpty {
            return NSAttributedString(
                string: subtitle,
                attributes: [.foregroundColor: UIColor.lightGray]
            )
        }

        if description.isEmpty {
            return NSAttributedString(
                string: title,
                attributes: [.foregroundColor: UIColor.white]
            )
        }

        let titleAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.lightGray]
        let fullString = "\(title): \(subtitle)"
        let attributedString = NSMutableAttributedString(string: fullString, attributes: titleAttributes)

        if let subtitleRange = fullString.range(of: subtitle) {
            if subtitle == title {
                let range = NSRange(location: fullString.count - subtitle.count, length: subtitle.count)
                attributedString.addAttributes(subtitleAttributes, range: range)
            } else {
                attributedString.addAttributes(subtitleAttributes, range: subtitleRange)
            }
        }

        return attributedString
    }
}
