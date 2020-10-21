//
//  InviteCollabarionsViewController.swift
//  
//
//  Created by Egor Kitselyuk on 16/01/2018.
//  Copyright © 2018 . All rights reserved.
//

import Contacts
import ContactsUI
import Foundation
import MessageUI
import PhoneNumberKit
import UIKit

class PHInviteCollaboratorViewController: BaseViewController {

    typealias Dependencies = HasAnalyticsService

    private let dependencies: Dependencies = ServiceContainer()
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var searchBar: UISearchBar!

    var project: Project? {
        guard let tabBarController = self.tabBarController as? PHTabBarViewController else {
            return nil
        }
        return tabBarController.project
    }

    var contacts: [CNContact] = []
    var filtredContacts: [CNContact] = []
    var selectedContacts: [CNContact] = []
    let dispatchSemaphore = DispatchSemaphore(value: 0)
    let dispatchGroup = DispatchGroup()
    var networkStatusService = NetworkStatusService.sharedInstance
    let syncService = SyncService.sharedInstance

    var sendMessageComletion: () -> Void = {}

    override func viewDidLoad() {
        super.viewDidLoad()

        networkStatusService.delegate.addDelegate(delegate: self)

        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .singleLine
        self.tableView.separatorColor = UIColor(hexString: "#767676")
        self.tableView.separatorStyle = .none
        self.tableView.tableFooterView = UIView()
        self.tableView.layer.masksToBounds = true

        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        nextButton.layer.cornerRadius = 15
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        searchBar.delegate = self
        let subviews = searchBar.subviews
        for subview in subviews {
            if let textField = subview as? UITextField {
                textField.font = UIFont.systemFont(ofSize: 14.0)
                textField.layer.cornerRadius = 12.0
                textField.layer.borderWidth = 1.0
                textField.layer.borderColor = UIColor.gray.cgColor
            }
        }

        let store = CNContactStore()

        if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
            store.requestAccess(for: .contacts, completionHandler: { authorized, _ in
                if authorized {
                    self.contacts = self.getContacts(store: store)
                    self.filtredContacts = self.contacts
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            })
        } else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            self.contacts = self.getContacts(store: store)
//            self.fitredContacts = self.contacts
            self.tableView.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        networkStatusService.checkOfflineMode(offline: {
            self.networkNotReachable()
        }, online: {
            self.networkIsReachable()
        })
    }

    @objc func dismissKeyboard() {
        searchBar.endEditing(true)
    }

    func getContacts(store: CNContactStore) -> [CNContact] {
        guard let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactImageDataKey,
            CNContactThumbnailImageDataKey] as? [CNKeyDescriptor] else {
                return []
        }

        var allContainers: [CNContainer] = []
        do {
            allContainers = try store.containers(matching: nil)
        } catch {
            print("Error fetching containers")
        }

        var results: [CNContact] = []

        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)

            do {
                let containerResults = try store.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch)
                results.append(contentsOf: containerResults)
            } catch {
                print("Error fetching containers")
            }
        }
        return results
    }

    private func sendInvite(contact: CNContact, completion: @escaping () -> Void) {
        let userID = LoginManager.sharedInstance.userID
        let user = RealmService.sharedInstance.getUserBy(id: userID)
        guard let project = self.project else {
            completion()
            return
        }
        let invite = Invite()
        invite.email = contact.emailAddresses.first?.value as String?

        let phoneNumberKit = PhoneNumberKit()
        if let phoneString = contact.phoneNumbers.first?.value.stringValue,
           let phoneNumber = try? phoneNumberKit.parse(phoneString) {
            invite.phone = phoneNumberKit.format(phoneNumber, toType: .e164)
        }

        invite.userName = "\(contact.givenName) \(contact.familyName)"
        invite.message = user?.name
        invite.projectID = project.id
        self.onSendInviteClick(invite: invite, contact: contact, completion: completion)
    }

    private func processInvites(contacts: [CNContact], completion: @escaping () -> Void) {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "Invites")
        let dispatchSemaphore = DispatchSemaphore(value: 0)

        queue.async {
            for contact in contacts {
                group.enter()
                self.sendInvite(contact: contact) {
                    dispatchSemaphore.signal()
                    group.leave()
                }
                dispatchSemaphore.wait()
            }
            group.notify(queue: .main) {
                completion()
            }
        }
    }

    @IBAction private func onAddButtonClick(_ sender: UIButton) {
        guard !selectedContacts.isEmpty else {
            self.showAlert(message: "Select one or more contacts")
            return
        }

        self.searchBar.text = ""
        self.searchBar.resignFirstResponder()
        filtredContacts.removeAll()
        self.tableView.reloadData()

        self.showLoadingHUD()
        processInvites(contacts: selectedContacts) {
            self.hideLoadingHUD()
            self.syncService.syncNewRemoteObjects()
        }
    }

    private func revokeInvite(inviteID: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        Api.sharedInstance.deleteInviteBy(inviteID: inviteID, onSuccess: { _ in
            RealmService.sharedInstance.delete(inviteID: inviteID)
            completion(.success(()))
        }, onFailed: { (error) in
            let error = APIError(errorDescription: error)
            completion(.failure(error))
        })
    }

    private func updateUIAfterInvitingContact(_ contact: CNContact) {
        DispatchQueue.main.async {
            if let selectedIndex = self.selectedContacts.firstIndex(of: contact) {
                self.selectedContacts.remove(at: selectedIndex)
                self.tableView.reloadData()
            }
        }
    }

    @objc func onSendInviteClick(invite: Invite,
                                 contact: CNContact,
                                 completion: @escaping () -> Void) {

        func showNoEmailDialog(message: String, dynamicLink: String, inviteID: Int) {
            self.sendMessageComletion = completion
            let message = "This user did not add an email to the profile. Do you want to send him an SMS?"
            self.showCancellableActionAlert(title: "\(invite.userName!)", message: message, actionHandler: {
                if MFMessageComposeViewController.canSendText() {
                    let controller = MFMessageComposeViewController()
                    controller.body = "\(message) \(dynamicLink)/"
                    controller.recipients = [invite.phone ?? ""]
                    controller.messageComposeDelegate = self
                    DispatchQueue.main.async {
                        self.present(controller, animated: true)
                    }
                } else {
                    failure(message: "Your device can not send SMS")
                }
            }, cancellationHandler: { [weak self] in
                guard let self = self else {
                    return
                }
                self.revokeInvite(inviteID: inviteID) { result in
                    switch result {
                    case .failure(let error):
                        failure(message: error.localizedDescription)
                    case .success:
                        completion()
                    }
                }
            })
        }

        func failure(message: String) {
            var error = message
            if error.contains("The invite with phone") {
                error = "The invite with current phone number already exists"
            }
            self.showAlert(message: error) {
                completion()
            }
        }

        func success() {
            self.showAlert(message: "The invite has been sent to \(invite.userName!)") {
                completion()
            }
        }

        Api.sharedInstance.sendInvite(
            email: invite.email,
            name: invite.userName!,
            phone: invite.phone,
            projectID: invite.projectID,
            message: invite.message,
            onSuccess: { response in
                self.updateUIAfterInvitingContact(contact)
                let noPhone = invite.phone.isNilOrEmpty
                let noEmail = invite.email.isNilOrEmpty
                if !noPhone, noEmail, response.invitedByEmail == nil {
                    showNoEmailDialog(message: response.message ?? "",
                                       dynamicLink: response.dynamicLink ?? "",
                                       inviteID: response.id)
                } else {
                    self.updateUIAfterInvitingContact(contact)
                    self.dependencies.analyticsService.trackInviteSent(withID: response.id)
                    success()
                }
            }, onFailed: { error in
                self.updateUIAfterInvitingContact(contact)
                failure(message: error)
            })
    }
}

extension PHInviteCollaboratorViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            //            fitredContacts = contacts
            filtredContacts = []
        } else {
            filtredContacts = contacts.filter { contact -> Bool in
                let userName = "\(contact.givenName)".lowercased()
                return userName.contains(searchText.lowercased())
            }
            filtredContacts = filtredContacts.filter { !self.selectedContacts.contains($0) }
        }
        filtredContacts.sort { $0.givenName < $1.givenName }
        tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        //        fitredContacts = contacts
        filtredContacts = []
        tableView.reloadData()
        searchBar.becomeFirstResponder()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        self.searchBar.endEditing(true)
    }

}

extension PHInviteCollaboratorViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        switch result {
        case .cancelled: break
        case .failed: break
        case .sent: break
        @unknown default:
            break
        }

        self.dismiss(animated: true, completion: {
             self.sendMessageComletion()
            if self.contacts.isEmpty {
                self.navigationController?.popToRootViewController(animated: true)
            }
        })
    }
}

extension PHInviteCollaboratorViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return selectedContacts.count
        case 1:
            return filtredContacts.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0 where filtredContacts.count == 1:
            cell.roundedCorners(radius: 10)
        case 0:
            cell.roundedCorners(radius: 10, corners: [.topRight, .topLeft])
        case filtredContacts.count - 1:
            cell.roundedCorners(radius: 10, corners: [.bottomRight, .bottomLeft])
        default:
            cell.roundedCorners(radius: 0)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: ContactViewCell = tableView.dequeueReusableCell(withIdentifier: "contactViewCell")
            as? ContactViewCell else {
            return UITableViewCell()
        }
        switch indexPath.section {
        case 0:
            let contact = selectedContacts[indexPath.row]
            cell.setContact(contact: contact, isSelected: true)
            cell.project = project
            cell.index = indexPath.row
            cell.selectionStyle = .none
            return cell
        case 1:
            let contact = filtredContacts[indexPath.row]
//            let isSelected = selectedContacts.contains(contact)
            cell.setContact(contact: contact, isSelected: false)
            cell.project = project
            cell.index = indexPath.row
            cell.selectionStyle = .none
            return cell
        default:
            return cell
        }
    }
}

extension PHInviteCollaboratorViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ContactViewCell {
            switch indexPath.section {
            case 0:
                filtredContacts.append(selectedContacts[indexPath.row])
                self.selectedContacts.remove(at: indexPath.row)
                tableView.reloadData()
            case 1:
//                guard let index = self.selectedContacts.index(of: fitredContacts[indexPath.row]) else {
//            return }
                cell.select(flag: true)
                self.selectedContacts.append(filtredContacts[indexPath.row])
                filtredContacts.remove(at: indexPath.row)
                tableView.reloadData()
            default: break
            }

//            if cell.accessoryType == .checkmark {
//                if let index = self.selectedContacts.index(of: fitredContacts[indexPath.row]) {
//                    self.selectedContacts.remove(at: index)
//                    cell.select(flag: false)
//                }
//            } else {
//            }
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
//        if let cell = tableView.cellForRow(at: indexPath) as? ContactViewCell {
//            cell.select(flag: false)
//            if let index = selectedContacts.index(of: fitredContacts[indexPath.row]) {
//                selectedContacts.remove(at: index)
//            }
//        }
    }
}

extension PHInviteCollaboratorViewController: NetworkStatusServiceProtocol {
    func networkNotReachable() {
        nextButton.isEnabled = false
        nextButton.alpha = 0.5
        self.searchBar.placeholder = "Inviting disabled in offline mode"
        self.searchBar.isUserInteractionEnabled = false
    }

    func networkIsReachable() {
        nextButton.isEnabled = true
        nextButton.alpha = 1.0
        self.searchBar.placeholder = ""
        self.searchBar.isUserInteractionEnabled = true
    }
}
