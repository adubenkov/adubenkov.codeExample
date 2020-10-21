//
//  ToplinerCommentsViewController.swift
//  
//
//  Created by Andrey Dubenkov on 22/01/2018.
//  Copyright © 2018 . All rights reserved.
//

import AudioKit
import CRRefresh
import UIKit

final class PHChatViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    private enum Layout {
        static var defaultTextViewHeight: CGFloat = 36
        static var maxTextViewHeight: CGFloat = 108
    }

    typealias Dependencies = HasAnalyticsService

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet weak var textField: MultilineTextField!
    @IBOutlet weak var textFieldHeightConstraint: NSLayoutConstraint!

    private var comments: [ProjectComment] = []

    private let dependencies: Dependencies = ServiceContainer()

    var networkStatusService = NetworkStatusService.sharedInstance

    var project: Project? {
        guard let tabBarController = self.tabBarController as? PHTabBarViewController else {
            return nil
        }
        return tabBarController.project
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateReadStatus()
        updateComments()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DeepLinkManager.sharedInstance.showNotification = false
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification),
                                               name: .commentAdded, object: nil)

        networkStatusService.checkOfflineMode(offline: {
            self.networkNotReachable()
        }, online: {
            self.networkIsReachable()
        })
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        DeepLinkManager.sharedInstance.showNotification = true
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func updateReadStatus() {
        networkStatusService.checkOfflineMode(offline: {
        }, online: {
            self.comments.forEach { comment in
                if comment.userID != LoginManager.sharedInstance.userID && comment.isRead == false {
                    Api.sharedInstance.updateReadStatus(comment: comment, onSuccess: { _ in
                        print("Comment \(comment.id) updated")
                    }, onFailed: { _ in
                        print("error")
                    })            }
            }
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        networkStatusService.delegate.addDelegate(delegate: self)

        tableView.delegate = self
        tableView.dataSource = self

        tableView.tableFooterView = UIView()

        tableView.cr.addHeadRefresh(animator: FastAnimator()) { [weak self] in
            self?.updateComments(isRefresh: true)
        }
        textField.delegate = self
        textField.layer.backgroundColor = UIColor(hexString: "#111112").cgColor
        textField.placeholderColor = UIColor(hexString: "#787878")
        textField.layer.cornerRadius = 12
        textField.textColor = .white
        textField.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 44)
        if #available(iOS 13.0, *) {
            textField.automaticallyAdjustsScrollIndicatorInsets = false
        }
        textField.layout()
        updateComments(isRefresh: false)
    }

    @objc func handleNotification() {
        updateComments()
    }

    @IBAction func sendButtonPressed(_ sender: Any) {
        if let text = textField.text {
            clickSendMessageButton(text: text)
            textField.text = ""
            updateHeight(textField)
        }
    }

    func setPlaceholder(text: String) {
        textField.placeholderColor = UIColor(hexString: "#787878")
        textField.placeholder = text
    }

    func updateComments(isRefresh: Bool = false) {
        networkStatusService.checkOfflineMode(offline: {
            self.tableView?.cr.endHeaderRefresh()
        }, online: {
            guard let project = self.project else {
                return
            }
            if isRefresh {
                self.tableView?.cr.beginHeaderRefresh()
            }
            Api.sharedInstance.getProjectComments(projectID: project.id, onSuccess: { comments in
                self.comments = comments.sorted { comment1, comment2 -> Bool in
                    return comment1.createdAt! > comment2.createdAt!
                }
                if isRefresh {
                    self.tableView?.cr.endHeaderRefresh()
                }
                self.tableView?.reloadData()
            }, onFailed: { error in
                if isRefresh {
                    self.tableView?.cr.endHeaderRefresh()
                }
                self.showAlert(message: error)
            })
        })
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: ProjectCommentViewCell = self.tableView.dequeueReusableCell(
            withIdentifier: "ProjectCommentCell") as? ProjectCommentViewCell else {
                return UITableViewCell()
        }
        guard let comment = comments[safe: indexPath.row] else {
            return cell
        }
        cell.set(comment: comment)
        return cell
    }

    func clickSendMessageButton(text: String) {
        guard !text.isEmpty else {
            return
        }

        view.endEditing(true)

        guard let project = self.project else {
            self.showAlert(message: "This take is empty")
            return
        }

        let comment = ProjectComment()
        comment.projectID = project.id
        comment.message = text
        comment.timePoint = 0
        comment.createdAt = Date()
        comment.updatedAt = Date()
        comment.isRead = false
        comment.user = RealmService.sharedInstance.getUserBy(id: LoginManager.sharedInstance.userID)
        comment.userID = LoginManager.sharedInstance.userID

        self.comments.insert(comment, at: 0)
        self.tableView?.reloadData()

        Api.sharedInstance.postProjectComment(comment: comment, onSuccess: { _ in
            self.updateComments()
            self.dependencies.analyticsService.trackCommentPosted(withID: comment.id)
        }, onFailed: { error in
            self.showAlert(message: error)
        })
    }
}

extension PHChatViewController: NetworkStatusServiceProtocol {
    func networkNotReachable() {
        textField.isUserInteractionEnabled = false
        setPlaceholder(text: "Messages are disabled in offline mode")
    }

    func networkIsReachable() {
        setPlaceholder(text: "Message")
        textField.isUserInteractionEnabled = true
        if LoginManager.sharedInstance.loggedIn {
            updateComments()
            updateReadStatus()
        }
    }
}

extension PHChatViewController: UITextViewDelegate {

    private func updateHeight(_ textView: UITextView) {
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let maxSize = min(newSize.height, Layout.maxTextViewHeight)
        textFieldHeightConstraint.constant = max(maxSize, Layout.defaultTextViewHeight)
        textField.layout()
    }

    func textViewDidChange(_ textView: UITextView) {
        updateHeight(textView)
    }
}
