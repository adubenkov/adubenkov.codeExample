//
//  PHCollabViewController.swift
//  
//
//  Created by Andrey Dubenkov on 27/05/2018.
//  Copyright © 2018 . All rights reserved.
//

import UIKit
import RealmSwift
import FileKit
import AudioKit
import MessageUI

class PHCollabViewController: BaseViewController {

    @IBOutlet private weak var avatarImage: UIImageView!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var nameLabel: UILabel!

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var resendInviteButton: UIButton!

    @IBOutlet private weak var noTakesLAbel: UILabel!

    var project: Project? {
        guard let tabBarController = self.tabBarController as? PHTabBarViewController else {
            return nil
        }
        return tabBarController.project
    }

    var collaboratorID: Int?
    var collaborator: Collaborator? {
        guard let id = collaboratorID else {
            return nil
        }
        let collabs = project?.makeCollaborators()
        return collabs?.first { $0.userID == id }
    }

    var takes: Results<Take>?

    var networkStatusService = NetworkStatusService.sharedInstance
    var syncService = SyncService.sharedInstance

    private lazy var dataManager: RealmService = .sharedInstance

    var notificationProjectsToken: NotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let collaborator = collaborator,
              let project = self.project else {
            return
        }
        self.takes = dataManager.getTake(projectID: project.id,
                                         userID: collaborator.userID)
        syncService.delegate.addDelegate(delegate: self)
        networkStatusService.delegate.addDelegate(delegate: self)

        configView()

        self.notificationProjectsToken = takes?.observe { (changes: RealmCollectionChange) in
            switch changes {
            case .initial:
                self.tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                self.tableView.beginUpdates()
                if !deletions.isEmpty {
                    self.tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0) }),
                                              with: .automatic)
                }

                if !insertions.isEmpty {
                    self.tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                                              with: .automatic)
                }

                if !modifications.isEmpty {
                    self.tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                                              with: .automatic)
                }
                self.tableView.endUpdates()
            case .error(let error):
                print("\(error)")
            }
        }
    }

    func configView() {
        avatarImage.roundedCorners(radius: 45.0)

        self.tableView.separatorStyle = .none
        self.tableView.delaysContentTouches = false
        guard let collaborator = collaborator,
              let project = self.project else {
            return
        }
        print(
            """
            Collab: \(collaborator.name) id: \(collaborator.userID),
            inviteID:\(collaborator.inviteID ?? 0)
            projcreator:\(String(describing: project.owner?.id))
            """
        )

        nameLabel.text = collaborator.name

        if collaborator.userID == LoginManager.sharedInstance.userID {
            self.resendInviteButton.isHidden = true
            self.closeButton.isHidden = true
        } else if project.isMyProject {
            self.resendInviteButton.isHidden = !collaborator.isInvitedUser
            self.closeButton.isHidden = false
        } else {
            self.resendInviteButton.isHidden = true
            self.closeButton.isHidden = true
        }

        if let photoURL = collaborator.photoURL {
            avatarImage.downloadedFrom(url: photoURL)
        } else {
            avatarImage.image = #imageLiteral(resourceName: "Avatar Placeholder")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        networkStatusService.checkOfflineMode(offline: {
            self.closeButton.isEnabled = false
            self.resendInviteButton.isEnabled = false
        }, online: {
            self.closeButton.isEnabled = true
            self.resendInviteButton.isEnabled = true
        })

        syncService.syncNewLocalObjects(completion: {_, _ in
            self.syncService.syncNewRemoteObjects()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction private func closeButtonPressed(_ sender: Any) {
        guard let collaborator = collaborator else {
            return
        }
        if collaborator.isInvitedUser,
            let inviteID = collaborator.inviteID {
            revokeInvite(inviteID: inviteID)
        } else {
            let message = "Are you sure that you want to remove \(collaborator.name) from the project?"
            self.showCancellableActionAlert(title: "Attention", message: message, actionHandler: {
                guard let id = self.project?.id else {
                    return
                }
                self.removeUserFromProject(projectID: id, userID: collaborator.userID)
            })
        }
    }

    func removeUserFromProject(projectID: Int, userID: Int ) {
        networkStatusService.checkOfflineMode(offline: {
            self.showAlert(message: "You can't perform this action in offline mode.")
        }, online: {
            self.showLoadingHUD()
            Api.sharedInstance.removeUserFromProjectBy(projectID: projectID, userID: userID, onSuccess: ({ _ in
                self.syncService.syncNewRemoteObjects {
                    self.hideLoadingHUD()
                    self.navigationController?.popViewController(animated: true)
                }
            }), onFailed: { error in
                self.showAlert(message: error)
            })
        })
    }

    func revokeInvite(inviteID: Int) {
        func revokeInvite() {
            showLoadingHUD()
            Api.sharedInstance.deleteInviteBy(inviteID: inviteID, onSuccess: { [weak self] _ in
                guard let self = self else {
                    return
                }

                self.dataManager.delete(inviteID: inviteID)
                self.hideLoadingHUD()
                self.showAlert(message: "The invite has been revoked") {
                    self.navigationController?.popViewController(animated: true)
                    #warning("Check Colloborators refreshed after invite revoking")
                }

                }, onFailed: { [weak self] (error) in
                    guard let self = self else {
                        return
                    }

                    self.hideLoadingHUD()
                    self.showAlert(message: error)
            })
        }

        NetworkStatusService.sharedInstance.checkOfflineMode(offline: {
            let message =  "Now you currently in offline mode or our server is temporarily unreachable. Please try again later."
            self.showAlert(message: message)
        }, online: {
            revokeInvite()
        })
    }

    @IBAction private func resendInvitePressed(_ sender: Any) {
        guard let collaborator = collaborator,
            collaborator.isInvitedUser,
            let inviteID = collaborator.inviteID else {
                return
        }
        NetworkStatusService.sharedInstance.checkOfflineMode(offline: {
            let message = "Now you currently in offline mode or our server is temporarily unreachable. Please try again later."
            self.showAlert(message: message)
        }, online: {
            self.showLoadingHUD()
            Api.sharedInstance.resendInvite(withID: inviteID) { result in
                self.hideLoadingHUD()

                switch result {
                case .failure(let error):
                    let errorMessage = error.localizedDescription
                    guard errorMessage != "The invite hasn't email address" else {
                        self.showAlert(message: errorMessage)
                        return
                    }
                case .success(let invite):
                    if !invite.email.isNilOrEmpty {
                        self.showAlert(message: "Invite has been resent")
                        return
                    }

                    let title = "\(invite.userName ?? "")"
                    let message = "This user did not add an email to the profile. Do you want to send him an SMS?"
                    self.showCancellableActionAlert(title: title, message: message, actionHandler: {
                        if MFMessageComposeViewController.canSendText() {
                            let controller = MFMessageComposeViewController()
                            controller.body = "\(invite.message ?? "") \(invite.dynamicLink ?? "")/"
                            controller.recipients = [invite.phone ?? ""]
                            controller.messageComposeDelegate = self
                            DispatchQueue.main.async {
                                self.present(controller, animated: true)
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.showAlert(message: "Your device can not send SMS")
                            }
                        }
                    })
                }
            }
        })
    }

    func selectTake(takeID: Int) {
        guard let index = indexForTake(id: takeID) else {
            return
        }
        let indexPath = IndexPath(row: index, section: 0)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
        tableView.delegate?.tableView!(tableView, didSelectRowAt: indexPath)
    }

    func indexForTake(id: Int) -> Int? {
        guard let takes = takes else {
            return nil
        }
        return takes.firstIndex { $0.id == id }
    }
}

extension PHCollabViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = self.tableView.dequeueReusableCell(withIdentifier: PHTakeTableViewCell.reuseID)
            as? PHTakeTableViewCell else {
                return
        }
        guard let takes = takes else {
            return
        }
        cell.setSeparatorIsHidden(showSeparator: indexPath.row == takes.count - 1 )
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let project = project,
            let take = takes?[indexPath.row] else {
                return nil
        }

        let copyAction = UIContextualAction(style: .normal, title: "Edit") { [unowned self] _, _, _ in
            self.tableView.setEditing(false, animated: true)
            self.copyTake(take: take)
        }
        copyAction.backgroundColor = UIColor(hexString: "#2da40a")

        if !take.isMyTake {
            return UISwipeActionsConfiguration(actions: [copyAction])
        } else {
            let exportAction = UIContextualAction(style: .normal, title: "Export") { [unowned self] _, _, _ in
                self.tableView.setEditing(false, animated: true)
                self.exportTake(take, project: project)
            }

            let renameAction = UIContextualAction(style: .normal, title: "Rename") { [unowned self] _, _, _ in
                self.tableView.setEditing(false, animated: true)
                self.renameTake(take)
            }
            renameAction.backgroundColor = UIColor(hexString: "#4A90E2")

            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [unowned self] _, _, _ in
                self.tableView.setEditing(false, animated: true)
                self.deleteTake(take)
            }

            return UISwipeActionsConfiguration(actions: [deleteAction, exportAction, renameAction])
        }
    }

    func copyTake(take: Take) {
        guard take.media?.isLocalUrlHere ?? false else {
            self.showAlert(message: "You should open this take first")
            return
        }
        self.showLoadingHUD()
        dataManager.copyTake(take) { result in
            self.hideLoadingHUD()
            switch result {
            case .failure(let error):
                self.showAlert(message: "An error occurred during copying: \(error.localizedDescription)")
            case .success:
                self.showAlert(message: "The take has been added to your takes list")
            }
        }
    }

    private func renameTake(_ take: Take) {
        networkStatusService.checkOfflineMode(offline: {
            if take.notSyncedCreate {
                self.presentRenameTakeAlert(for: take)
            } else {
                self.showAlert(message: "You can't rename this take in Offline mode")
            }
        }, online: {
            self.presentRenameTakeAlert(for: take)
        })
    }

    private func presentRenameTakeAlert(for take: Take) {
        let alertController = UIAlertController(title: "", message: "Please input take title", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = take.name
        }
        alertController.addAction(UIAlertAction(title: "Set", style: .default) { [unowned self, unowned alertController] _ in
            guard let newName = alertController.textFields?.first?.text else {
                return
            }
            self.updateTake(take, newName: newName)
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alertController, animated: true)
    }

    private func updateTake(_ take: Take, newName: String) {
        // Update local take object
        dataManager.updateTakeName(takeID: take.id, name: newName)

        // Take must exists on the backend
        guard !take.notSyncedCreate else {
            return
        }

        showLoadingHUD()
        let parameters = ["name": take.name]
        Api.sharedInstance.updateTake(withID: take.id, parameters: parameters) { [weak self] result in
            guard let self = self else {
                return
            }

            self.hideLoadingHUD()
            switch result {
            case .failure(let error):
                let errorMessage = error.localizedDescription
                if errorMessage != "Take does not exist" {
                    self.showAlert(message: errorMessage)
                }
            case .success:
                self.tableView.reloadData()
            }
        }
    }

    private func deleteTake(_ take: Take) {
        let message = "Are you sure you want to delete this take?"
        showCancellableActionAlert(title: "Warning", message: message, actionHandler: { [unowned self] in
            self.dataManager.updateTakeIsSyncedDeleted(id: take.id, notSynced: true)
            SyncService.sharedInstance.syncLocalDeletedObjects { [weak self] in
                guard let self = self else {
                    return
                }
                self.tableView.isEditing = false
                self.tableView.reloadData()
            }
            }, cancellationHandler: { [unowned self] in
                DispatchQueue.main.async {
                    self.tableView.isEditing = false
                    self.tableView.reloadData()
                }
        })
    }

    private func exportTake(_ take: Take, project: Project) {
        func exportFile(_ file: AKAudioFile, filename: String) {
            self.showLoadingHUD()
            AKAudioFile.exportAudioFile(audioFile: file, fileName: filename, baseDir: .documents) { [weak self] result in
                guard let self = self else {
                    return
                }
                self.hideLoadingHUD()
                switch result {
                case .failure(let error):
                    self.showAlert(message: error.localizedDescription)
                case .success(let file):
                    guard let url = file?.url else {
                        self.showAlert(message: "Export error")
                        return
                    }
                    let controller = UIActivityViewController(activityItems: [url], applicationActivities: [])
                    self.present(controller, animated: true)
                }
            }
        }

        guard take.mediaID != 0,
              let media = take.media else {
            self.showAlert(message: "This take has no audio")
            return
        }

        let dateTransform = DateFormatter.serverDateFormatter()
        let date = dateTransform.transformToJSON(take.updatedAt)
        let projectName = project.name
        let filename = "\(projectName)_\(date!)".stringForFilePath
        let newpath = Path.userDocuments + "/\(filename).mp4"

        //Removing old exported file
        if newpath.exists {
            try? FileManager.default.removeItem(at: newpath.url)
        }

        CacheService.sharedInstance.getAudioFile(forMediaWithID: media.id) { [weak self] result in
            guard let self = self else {
                return
            }
            self.hideLoadingHUD()

            switch result {
            case .failure(let error):
                self.showAlert(message: error.localizedDescription)
            case .success(let file):
                print("Export fromFormat:\(file.fileFormat)")
                print("Export file:\(file.url)")
                exportFile(file, filename: filename)
            }
        }
    }
}

extension PHCollabViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let takes = takes else {
            return 0
        }
        let hasTakes = !takes.isEmpty
        self.noTakesLAbel.isHidden = hasTakes
        tableView.backgroundView = nil
        return takes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = self.tableView.dequeueReusableCell(withIdentifier: PHTakeTableViewCell.reuseID)
            as? PHTakeTableViewCell else {
                return UITableViewCell() }
        guard let takes = takes else {
            return cell }
        guard let take = takes[safe: indexPath.row] else {
            return cell }

        cell.indexPath = indexPath
        cell.set(take: take)

        networkStatusService.checkOfflineMode(offline: {
            if let media = take.media {
                guard !take.notSyncedCreate else {
                    cell.set(disabled: false)
                    return
                }
                let islocal = media.isLocalUrlHere
                if islocal {
                    cell.set(disabled: false)
                } else {
                    cell.set(disabled: true)
                }
                return
            } else {
                cell.set(disabled: false)
            }
        }, online: {
            cell.set(disabled: false)
        })
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let takes = takes,
              let project = self.project else {
            return
        }
        let take = takes[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        NotificationCenter.default.post(name: .goToTake, object: (project.id, take.id))
    }
}

extension PHCollabViewController: NetworkStatusServiceProtocol {

    func networkNotReachable() {
        self.tableView.reloadData()
        closeButton.isEnabled = false
        resendInviteButton.isEnabled = false
    }

    func networkIsReachable() {
        self.tableView.reloadData()
        closeButton.isEnabled = true
        resendInviteButton.isEnabled = true
    }
}

extension PHCollabViewController: SyncServiceOutput {

    func workingOnProject(id: Int) {

    }

    func syncStarted() {

    }

    func syncCompleted() {
        #warning("Check refreshing coloborators after sync ended")
    }

    func syncError(error: String) {

    }

}
extension PHCollabViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {

    }
}
