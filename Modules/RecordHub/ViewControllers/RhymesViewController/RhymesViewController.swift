//
//  RhymesViewController.swift
//  
//
//  Created by Andrey Dubenkov on 22/01/2018.
//  Copyright © 2018 . All rights reserved.
//

import UIKit

class RhymesViewController: BaseViewController,
                                    UITableViewDelegate,
                                    UITableViewDataSource {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var searchBar: UISearchBar!

    var groups: [Int: [String]] = [:]
    var networkStatusService = NetworkStatusService.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

        networkStatusService.delegate.addDelegate(delegate: self)
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self

        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableView.automaticDimension

        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(onDoneButtonClick))
        doneButton.tintColor = UIColor.black
        toolbar.setItems([flexibleSpace, doneButton], animated: false)

        searchBar.inputAccessoryView = toolbar
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        networkStatusService.checkOfflineMode(offline: {
            self.networkNotReachable()
        }, online: {
            self.networkIsReachable()
        })
    }

    @objc func onDoneButtonClick() {
        if let query = searchBar.text, !query.isEmpty {
            self.search(query: query)
        }
        self.view.endEditing(true)
    }

    func search(query: String) {
        self.showLoadingHUD()
        groups = [:]

        networkStatusService.checkOfflineMode(offline: {
            self.searchBar.text = ""
            self.showAlert(message: "Only local audio and data can be accessed", title: "Offline mode")
        }, online: {
            Api.sharedInstance.fetchRhymes(withQuery: query) { [weak self] result in
                guard let self = self else {
                    return
                }
                self.hideLoadingHUD()
                switch result {
                case .failure(let error):
                    self.showAlert(message: error.localizedDescription)
                case .success(let response):
                    response.sections.forEach { section in
                        section.rhymes.forEach { rhyme in
                            if self.groups[rhyme.numberOfSyllables] == nil {
                                self.groups[rhyme.numberOfSyllables] = []
                            }
                            self.groups[rhyme.numberOfSyllables]?.append(rhyme.word)
                        }
                    }
                    self.tableView.reloadData()
                }
            }
        })
    }

    func attributedString(from string: String, nonBoldRange: NSRange?) -> NSAttributedString {
        let fontSize = UIFont.systemFontSize
        let attrs = [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: fontSize),
            NSAttributedString.Key.foregroundColor: UIColor.black
        ]
        let nonBoldAttribute = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)]
        let attrStr = NSMutableAttributedString(string: string, attributes: attrs)
        if let range = nonBoldRange {
            attrStr.setAttributes(nonBoldAttribute, range: range)
        }
        return attrStr
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = self.tableView.dequeueReusableCell(withIdentifier: "rhymeCell") as? RhymesViewCell else {
            return UITableViewCell()
        }

        let syllableCount = Array(groups.keys)[indexPath.row]
        cell.set(syllable: syllableCount, rhymes: groups[syllableCount]!)
        cell.layoutIfNeeded()

        return cell
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if let text = searchBar.text {
            search(query: text)
        }
    }
}

extension RhymesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.groups = [:]
                self.tableView.reloadData()
                searchBar.resignFirstResponder()
            }
        }
    }
}

extension RhymesViewController: NetworkStatusServiceProtocol {
    func networkNotReachable() {
        self.searchBar.isUserInteractionEnabled = false
    }

    func networkIsReachable() {
        self.searchBar.isUserInteractionEnabled = true
    }
}
