//
//  ToplinerLyricsViewController.swift
//  
//
//  Created by Andrey Dubenkov on 22/01/2018.
//  Copyright © 2018 . All rights reserved.
//

import UIKit

class ToplinerLyricsViewController: BaseViewController {
    @IBOutlet private var textView: MultilineTextField!
    private var take: Take?
    private var lyrics: String?

    var networkStatusService = NetworkStatusService.sharedInstance

    func set(take: Take) {
        self.take = take
        lyrics = take.lyrics
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateLyricNotification(notification:)),
                                               name: NSNotification.Name(rawValue: "updateLyric"),
                                               object: nil)
    }

    private func configureView() {
        textView.placeholderColor = UIColor.gray
        textView.isPlaceholderScrollEnabled = true
        textView.leftViewOrigin = CGPoint(x: 48, y: 8)
        textView.placeholderTextAligment = .center
        textView.delegate = self
        textView.textContainerInset = UIEdgeInsets(top: 15, left: 40, bottom: 15, right: 40)
        guard let take = take else {
            return
        }
        textView.placeholder = take.isMyTake ? "Enter lyrics here" : ""
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateLyric()
    }

    func updateLyric() {
        guard let take = take else {
            return
        }
        lyrics = take.lyrics
        textView.text = lyrics
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        guard let identifier = identifier,
            identifier == "toLyricsEditor",
            take?.isMyTake ?? false else {
            return false
        }
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier,
            identifier == "toLyricsEditor",
            let navController = segue.destination as? UINavigationController,
            let controller = navController.viewControllers.first as? LyricsEditViewController,
            let take = self.take else {
            return
        }

//        controller.modalPresentationStyle = .pageSheet
//        controller.modalPresentationCapturesStatusBarAppearance = true
        controller.take = take
        controller.lyric = take.lyrics
    }

    @objc func updateLyricNotification(notification: Notification) {
        if (notification.object as? String) != nil {
            updateLyric()
        }
    }
}

extension ToplinerLyricsViewController: UITextViewDelegate {
    override var canBecomeFirstResponder: Bool {
        return false
    }
}

class PassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
}
