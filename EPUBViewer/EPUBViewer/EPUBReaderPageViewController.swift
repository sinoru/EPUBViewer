//
//  EPUBReaderPageViewController.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/14.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import UIKit
import EPUBKit
import SwiftUI

class EPUBReaderPageViewController: UIViewController {
    static let pageBufferSize = 1
    typealias WebViewController = EPUBReaderWebViewController

    var epub: EPUB?

    private var pageViewController: _PageViewController?

    private var previousWebViewControllers = [WebViewController]()
    private var nextWebViewControllers = [WebViewController]()

    func updateWebViewControllers(reusableWebViewControllers: [WebViewController] = []) {
        let currentViewController = pageViewController?.viewControllers ?? []
        let isDoubleSided = pageViewController?.isDoubleSided ?? true

        let pageBufferSize = (isDoubleSided ? Self.pageBufferSize * 2 : Self.pageBufferSize)

        var reusableWebViewControllers = reusableWebViewControllers

        previousWebViewControllers.removeAll(where: { currentViewController.contains($0) })
        nextWebViewControllers.removeAll(where: { currentViewController.contains($0) })

        if previousWebViewControllers.count < pageBufferSize {
            (1...(pageBufferSize - previousWebViewControllers.count)).forEach { (_) in

            }
        }



        if nextWebViewControllers.count < pageBufferSize {

        }
    }

}

extension EPUBReaderPageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let previousViewControllers = previousViewControllers as? [WebViewController] else {
            fatalError("previousViewControllers should be \([WebViewController].self)")
        }

        updateWebViewControllers(reusableWebViewControllers: previousViewControllers)
    }
}

extension EPUBReaderPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return previousWebViewControllers.last
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return nextWebViewControllers.first
    }
}

extension EPUBReaderPageViewController {
    private class _PageViewController: UIPageViewController {

    }
}

