//
//  RecordHubPageViewController.swift
//  
//
//  Created by Andrey Dubenkov on 03/06/2018.
//  Copyright © 2018 . All rights reserved.
//

import UIKit

class RecordHubPageViewController: UIPageViewController, UIPageViewControllerDelegate {

    var pages = [UIViewController]()

    var projectID: Int?
    var takeID: Int?

    var project: Project? {
        guard let id = projectID else {
            return nil
        }
        return RealmService.sharedInstance.getProject(withID: id)
    }

    var take: Take? {
        guard let id = takeID else {
            return nil
        }
        return RealmService.sharedInstance.getTake(id: id)
    }

    private var currentIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.dataSource = self

        let storyboard = UIStoryboard(name: "RecordHubStoryboard", bundle: nil)

        if let page1 = storyboard.instantiateViewController(withIdentifier: "ToplinerLyricsViewController") as? ToplinerLyricsViewController,
            let take = take {
            pages.append(page1)
            page1.set(take: take)
        }

        if let page2 = storyboard.instantiateViewController(withIdentifier: "Rhymes") as? RhymesViewController {
            pages.append(page2)
        }

        guard let first = pages.first else {
            return
        }
        setViewControllers([first], direction: UIPageViewController.NavigationDirection.forward, animated: false, completion: nil)
    }
}

extension RecordHubPageViewController: UIPageViewControllerDataSource {
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pages.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return currentIndex
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {

        let cur = pages.firstIndex(of: viewController)!

        // if you prefer to NOT scroll circularly, simply add here:
        if cur == 0 {
            return nil
        }

        var prev = (cur - 1) % pages.count
        if prev < 0 {
            prev = pages.count - 1
        }
        return pages[prev]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {

        let cur = pages.firstIndex(of: viewController)!

        // if you prefer to NOT scroll circularly, simply add here:
        if cur == (pages.count - 1) {
            return nil
        }

        let nxt = abs((cur + 1) % pages.count)
        return pages[nxt]
    }
}
