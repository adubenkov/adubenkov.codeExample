//
//  OwnerProjectInfoViewController.swift
//  
//
//  Created by Andrey Dubenkov on 21/01/2018.
//  Copyright © 2018 . All rights reserved.
//

import AudioKit
import RealmSwift
import RSKPlaceholderTextView
import UIKit

protocol ProjectHubInfoViewOutput: class {
    func viewWillAppear(view: PHInfoViewController)
    func infoViewDidRequestDeleteProject(view: PHInfoViewController)
    func infoViewDidRequestLeaveProject(view: PHInfoViewController)
    func infoViewDidRequestUpdateParameterProject(view: PHInfoViewController, parameter: ParamName, value: String)
    func infoViewDidRequestUpdateProjectName(view: PHInfoViewController, value: String)
    func infoViewDidRequestUpdateProjectNotes(view: PHInfoViewController, value: String)

}

class PHInfoViewController: BaseViewController {
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var projectNameTextView: RSKPlaceholderTextView!
    @IBOutlet private weak var noteTextView: RSKPlaceholderTextView!
    @IBOutlet private weak var timeButton: UIButton!
    @IBOutlet private weak var tempoButton: UIButton!
    @IBOutlet private weak var keyButton: UIButton!
    @IBOutlet private weak var deleteProjectButton: UIButton!

    @IBOutlet private weak var noteheightConstraint: NSLayoutConstraint!

    var output: ProjectHubInfoViewOutput? {
        guard let tabBarController = self.tabBarController as? PHTabBarViewController else {
            return nil
        }
        return tabBarController.infoViewOtput
    }

    var project: Project? {
        guard let tabBarController = self.tabBarController as? PHTabBarViewController else {
            return nil
        }
        return tabBarController.project
    }

    private var isMyProject: Bool {
        return project?.isMyProject ?? false
    }

    // MARK: - viewController Lifesycycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupWithProject()
        output?.viewWillAppear(view: self)
    }

    func configView() {
        projectNameTextView.sizeToFit()
        projectNameTextView.textContainerInset = UIEdgeInsets(top: 22, left: 15, bottom: 22, right: 10)
        noteTextView.sizeToFit()
        noteTextView.textContainerInset = UIEdgeInsets(top: 22, left: 15, bottom: 22, right: 10)
        deleteProjectButton.layer.cornerRadius = 15

        projectNameTextView.delegate = self
        noteTextView.delegate = self

        let fixedWidth = noteTextView.frame.size.width
        noteTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let newSize = noteTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        self.noteheightConstraint.constant = newSize.height
        self.view.layoutIfNeeded()

        projectNameTextView.isScrollEnabled = false
        noteTextView.isScrollEnabled = false
    }

    private func setupWithProject() {
        projectNameTextView.text = project?.name ?? ""
        noteTextView.text = project?.notes ?? ""
        let time = project?.timeSignature
        timeButton.setTitle(time, for: .normal)
        let key = project?.key
        keyButton.setTitle(key, for: .normal)
        let tempoString = "\(project?.tempo ?? 0)"
        tempoButton.setTitle(tempoString, for: .normal)
        if !isMyProject {
            self.deleteProjectButton.setTitle("LEAVE PROJECT", for: .normal)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let theDestination = segue.destination as? PopUpViewController {
            theDestination.delegate = self
        }
    }

    func lockInterface() {
        self.deleteProjectButton.isEnabled = false
        self.deleteProjectButton.alpha = 0.5
        self.timeButton.isEnabled = false
        self.tempoButton.isEnabled = false
        self.keyButton.isEnabled = false
        self.noteTextView.isUserInteractionEnabled = false
        self.projectNameTextView.isUserInteractionEnabled = false
    }

    func unlockInterface() {
        self.timeButton.isEnabled = true
        self.tempoButton.isEnabled = true
        self.keyButton.isEnabled = true
        self.noteTextView.isUserInteractionEnabled = true
        self.projectNameTextView.isUserInteractionEnabled = true
        self.deleteProjectButton.isEnabled = true
        self.deleteProjectButton.alpha = 1.0

        self.timeButton.isEnabled = isMyProject
        self.tempoButton.isEnabled = isMyProject
        self.keyButton.isEnabled = isMyProject
        self.projectNameTextView.isUserInteractionEnabled = isMyProject
        self.noteTextView.isUserInteractionEnabled = isMyProject

        guard let notes = project?.notes else {
            return
        }
        if !isMyProject && notes.isEmpty {
            self.noteTextView.isHidden = true
        }
    }

    // MARK: - Actions

    @IBAction private func timeButtonPressed(_ sender: Any) {
    }

    @IBAction private func tempoButtonPressed(_ sender: Any) {
    }

    @IBAction private func keyButtonPressed(_ sender: Any) {
    }

    @IBAction private func deleteButtonPressed(_ sender: Any) {
        if isMyProject {
            let message = "Are you sure that you want to remove this project?"
            showCancellableActionAlert(title: "Attention",
                                       message: message,
                                       actionHandler: { [unowned self] in
                self.output?.infoViewDidRequestDeleteProject(view: self)
            })
        } else {
            let message = "Are you sure that you want to leave this project?"
            showCancellableActionAlert(title: "Attention",
                                       message: message,
                                       actionHandler: { [unowned self] in
                self.output?.infoViewDidRequestLeaveProject(view: self)
            })
        }
    }
}

extension PHInfoViewController: PopUpSelect {
    func itemSelected(kind: ParamName, value: String) {
        switch kind {
        case .time:
            self.timeButton.setTitle(value, for: .normal)
        case .key:
            self.keyButton.setTitle(value, for: .normal)
        case .tempo:
            self.tempoButton.setTitle(value, for: .normal)
        }
        output?.infoViewDidRequestUpdateParameterProject(view: self, parameter: kind, value: value)

    }
}

extension PHInfoViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        textView.frame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)

        self.noteheightConstraint.constant = newSize.height
        self.view.layoutIfNeeded()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == projectNameTextView {
            if let text = textView.text {
                output?.infoViewDidRequestUpdateProjectName(view: self, value: text)
            }
        }
        if textView == noteTextView {
            if let text = textView.text {
                output?.infoViewDidRequestUpdateProjectNotes(view: self, value: text)
            }
        }
    }
}
