//
//  LyricsEditViewController.swift
//  
//
//  Created by Andrey Dubenkov on 12/02/2018.
//  Copyright © 2018 . All rights reserved.
//

import UIKit

class LyricsEditViewController: UIViewController {

    @IBOutlet private var textField: MultilineTextField!
    @IBOutlet var shareButton: UIBarButtonItem!

    var take: Take?
    var lyric: String = ""

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        saveLyrics()
        super.viewWillDisappear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        textField.text = lyric

        textField.placeholder = "Lyrics Editor"
        textField.placeholderColor = UIColor.gray
        textField.isPlaceholderScrollEnabled = true
        textField.leftViewOrigin = CGPoint(x: 48, y: 8)
        textField.placeholderTextAligment = .center
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleKeyboard(_:)))
        view.addGestureRecognizer(tap)
    }

    @objc func handleKeyboard(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: textField)

        if !textField.bounds.contains(location) {
            view.endEditing(true)
        }
    }

    @IBAction private func leftbuttonpressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction private func rightButtonPressed(_ sender: Any) {
        guard let text = textField.text else {
            return
        }
        let viewController = UIActivityViewController(activityItems: [text],
                                                      applicationActivities: [])
        if let popoverController = viewController.popoverPresentationController {
            popoverController.barButtonItem = shareButton
            popoverController.sourceView = view
            popoverController.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        }
        present(viewController, animated: true)
    }

    func saveLyrics() {
        guard let take = take else {
            return
        }

        RealmService.sharedInstance.updateLyricsInTake(lyrics: textField.text, take: take)

        showLoadingHUD()
        SyncService.sharedInstance.syncLocalObjectChanges {
            self.hideLoadingHUD()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateLyric"),
                                            object: self.textField.text!)
            self.dismiss(animated: true)
        }
    }
}
