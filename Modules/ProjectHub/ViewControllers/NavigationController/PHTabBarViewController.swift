//
//  PHTabBarViewController.swift
//  
//
//  Created by Andrey Dubenkov on 04/11/2018.
//  Copyright © 2018 . All rights reserved.
//

import AudioKit
import UIKit

enum ActiveCommand {
    case showUser(id: Int)
    case showInvite(id: Int)
    case showMessage
}

class PHTabBarViewController: UITabBarController {
    var projectID: Int?

    var infoViewOtput: ProjectHubInfoViewOutput?
    var collaboratosViewOtput: ProjectHubToplinersCollectionViewOutput?

    var project: Project? {
        guard let id = projectID else {
            return nil
        }
        return RealmService.sharedInstance.getProject(withID: id)
    }

    private lazy var dataManager = RealmService.sharedInstance
    private lazy var syncService = SyncService.sharedInstance
    private lazy var networkStatusService: NetworkStatusService = .sharedInstance

    var activeCommand: ActiveCommand?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        infoViewOtput = self
        syncService.delegate.addDelegate(delegate: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: 2000)) {
            self.checkActiveCommand()
        }
    }

    // MARK: - Private

    private func checkActiveCommand() {
        guard let active = activeCommand else {
            return
        }
        switch active {
        case .showMessage:
            showComments()
            self.activeCommand = nil
        case .showUser(let id):
            showUser(userID: id)
            self.activeCommand = nil
        case .showInvite(let id):
            showInvite(userID: id)
            self.activeCommand = nil
        }
    }

    private func configureView() {
        guard let project = project else {
            return
        }
        if !project.isMyProject {
            if self.viewControllers?.contains(where: { $0 is PHInviteCollaboratorViewController }) ?? false {
                self.viewControllers?.remove(at: 0)
            }
        }

        refreshTopliners()
    }

    private func refreshTopliners() {
        guard let viewControllers = viewControllers else {
            return
        }
        if let index = viewControllers.firstIndex(where: { $0 is ToplinersCollectionViewController }),
            let topliners = viewControllers[safe: index] as? ToplinersCollectionViewController {
            topliners.reload()
        }
    }

    private func showComments() {
        guard let isMy = project?.isMyProject else {
            return
        }
        self.selectedIndex = isMy ?  1 : 0
    }

    private func showUser(userID: Int) {
        guard let isMy = project?.isMyProject else {
            return
        }

        let vcIndex = isMy ?  2 : 1
        self.selectedIndex = vcIndex

        guard let navigation = self.viewControllers?[vcIndex] as?  UINavigationController,
              let topliners = navigation.viewControllers.first as? ToplinersCollectionViewController else {
            return
        }

        guard let index = topliners.collaborators?.firstIndex(where: { collab in collab.userID == userID }) else {
            return
        }
        topliners.collectionView(topliners.collectionView!, didSelectItemAt: IndexPath(row: index, section: 0))
    }

    private func showInvite(userID: Int) {
        guard let isMy = project?.isMyProject else {
            return
        }
        let vcIndex = isMy ?  2 : 1
        self.selectedIndex = vcIndex

        guard let navigation = self.viewControllers?[vcIndex] as?  UINavigationController,
              let topliners = navigation.viewControllers.first as? ToplinersCollectionViewController else {
            return
        }

        guard let indexOfCollab = topliners.collaborators?.firstIndex(where: { collaborator in
            collaborator.isInvitedUser && collaborator.inviteID == userID
            }) else {
            return
        }
        topliners.collectionView(topliners.collectionView!, didSelectItemAt: IndexPath(row: indexOfCollab, section: 0))
    }

    private func deleteProject(_ project: Project) {
        func completion() {
            showAlert(message: "Project successfully deleted") {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }

        // Project is not exists on backend,
        // we just need to remove it from local db
        if project.notSyncedCreate {
            dataManager.deleteProject(withID: project.id)
            completion()
            return
        }

        // 1. We have to mark project as deleted in local db
        dataManager.updateLocalProjectDeletionStatus(projectID: project.id, isDeleted: true)

        // 2. Skip sync for deleted project, if we're offline
        if !networkStatusService.isReachable {
            completion()
            return
        }

        // 3. Sync deleted project if we're online
        view.isUserInteractionEnabled = false
        showLoadingHUD()
        syncService.syncDeletedProject(project, success: { [weak self] in
            guard let self = self else {
                return
            }
            self.hideLoadingHUD()
            self.view.isUserInteractionEnabled = true
            completion()
        }, failure: { [weak self] errorMessage in
            guard let self = self else {
                return
            }
            // Revert project changes, cause sync was failed
            self.dataManager.updateLocalProjectDeletionStatus(projectID: project.id, isDeleted: false)
            self.hideLoadingHUD()
            self.view.isUserInteractionEnabled = true
            self.showAlert(message: errorMessage)
        })
    }

    private func leaveProject(_ project: Project) {
        func completion() {
            showAlert(message: "You have successfully left this project") {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
        showLoadingHUD()
        Api.sharedInstance.leaveProject(projectID: project.id, onSuccess: { [weak self] _ in
            guard let self = self else {
                return
            }
            self.hideLoadingHUD()
            self.view.isUserInteractionEnabled = true
            completion()
        }, onFailed: { [weak self] errorMessage in
            guard let self = self else {
                return
            }
            self.hideLoadingHUD()
            self.view.isUserInteractionEnabled = true
            self.showAlert(message: errorMessage)
        })
    }
}
    // MARK: - ProjectHubInfoViewOutput
extension PHTabBarViewController: ProjectHubInfoViewOutput {

    func infoViewDidRequestUpdateProjectName(view: PHInfoViewController, value: String) {
        if let project = self.project {
            dataManager.update(object: project, paramName: "name", value: value, completion: nil)
            Api.sharedInstance.updateProject(project: project, onSuccess: {_ in
                self.showAlert(message: "Changes saved", title: "Message")
            }, onFailed: {error in
                self.showAlert(message: error)
            })
        }
    }

    func infoViewDidRequestUpdateProjectNotes(view: PHInfoViewController, value: String) {
        if let project = self.project {
            dataManager.update(object: project, paramName: "notes", value: value, completion: nil)
            Api.sharedInstance.updateProject(project: project, onSuccess: {_ in
                self.showAlert(message: "Changes saved", title: "Message")
            }, onFailed: {error in
                self.showAlert(message: error)
            })
        }
    }

    func infoViewDidRequestUpdateParameterProject(view: PHInfoViewController, parameter: ParamName, value: String) {
        if let project = self.project {
            switch parameter {
            case .time:
                dataManager.update(object: project, paramName: "timeSignature", value: value, completion: nil)
            case .key:
                dataManager.update(object: project, paramName: "key", value: value, completion: nil)
            case .tempo:
                let tempoString = value
                let tempo = Int(tempoString)
                dataManager.update(object: project, paramName: "tempo", value: tempo!, completion: nil)
            }
            dataManager.updateProjectIsSyncedUpdated(id: project.id, notSynced: true)
            SyncService.sharedInstance.syncLocalObjectChanges {
                self.showAlert(message: "Changes saved", title: "Message")
            }
        }
    }

    func infoViewDidRequestDeleteProject(view: PHInfoViewController) {
        guard let project = project else {
            return
        }
        deleteProject(project)
    }

    func infoViewDidRequestLeaveProject(view: PHInfoViewController) {
        guard let project = project else {
            return
        }
        leaveProject(project)
    }

    func viewWillAppear(view: PHInfoViewController) {
        view.unlockInterface()
    }
}

extension PHTabBarViewController: ProjectHubToplinersCollectionViewOutput {

}

extension PHTabBarViewController: SyncServiceOutput {
    func workingOnProject(id: Int) {
    }

    func syncStarted() {
    }

    func syncCompleted() {
    }

    func syncError(error: String) {
        self.showAlert(message: error)
    }
}

extension PHTabBarViewController: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        checkActiveCommand()
    }
}
