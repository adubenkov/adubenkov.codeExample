//
//  ToplinersCollectionViewController.swift
//  
//
//  Created by Andrey Dubenkov on 04/11/2018.
//  Copyright © 2018 . All rights reserved.
//

import AudioKit
import UIKit

private let reuseIdentifier = "toplineCollectionCell"

protocol ProjectHubToplinersCollectionViewOutput: class {

}

class ToplinersCollectionViewController: UICollectionViewController {

    var output: ProjectHubToplinersCollectionViewOutput? {
        guard let tabBarController = self.tabBarController as? PHTabBarViewController else {
            return nil
        }
        return tabBarController.collaboratosViewOtput
    }

    var project: Project? {
        guard let tabBarController = self.tabBarController as? PHTabBarViewController else {
            return nil
        }
        return tabBarController.project
    }

    var collaborators: [Collaborator]? {
        guard let project = self.project else {
            return []
        }
        return project.makeCollaborators()
    }

    var selectedCollab: Collaborator?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    func reload() {
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        guard let collabs = self.collaborators else {
            return 0
        }
        return collabs.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                            for: indexPath) as? ToplinerCollectionViewCell else {
            return UICollectionViewCell()
        }
            // Configure the cell
            guard let collabs = self.collaborators,
                let project = self.project else {
                return cell
            }
            let collab = collabs[indexPath.row]
            if let photoURL = collab.photoURL {
                cell.imageView.downloadedFrom(url: photoURL)
            } else {
                cell.imageView.image = #imageLiteral(resourceName: "Avatar Placeholder")
            }

            cell.imageView.roundedCorners(radius: 50)
            cell.nameLabel.text = collab.name
            let takes = RealmService.sharedInstance.getTake(projectID: project.id, userID: collab.userID)
            let count = takes.count
            switch count {
            case 0:
                cell.takesLabel.text = "No takes"
            case 1:
                cell.takesLabel.text = "1 take"
            default:
                cell.takesLabel.text = "\(count) takes"
        }
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let collabs = self.collaborators else {
            return
        }
        guard let collab = collabs[safe: indexPath.row] else {
            return
        }
        selectedCollab = collab
        self.performSegue(withIdentifier: "toTopliner", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {
        case "toTopliner":
             if let viewController = segue.destination as? PHCollabViewController {
                guard let selected = selectedCollab,
                      let project = self.project else {
                    return
                }
                viewController.collaboratorID = selected.userID
            }
        default:
            break
        }
    }
}
