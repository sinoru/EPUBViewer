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
    typealias WebViewController = UIHostingController<WebView>

    var epub: EPUB?

    private var pageViewController: _PageViewController?

    private var webViewControllers = [WebViewController]()

}

extension EPUBReaderPageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {

    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {

    }
}

extension EPUBReaderPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let webViewController = viewController as? WebViewController else {
            fatalError("viewController should be \(WebViewController.self) not \(type(of: viewController).self)")
        }

        return webViewControllers.firstIndex(of: webViewController).flatMap { self.webViewControllers[$0 < self.webViewControllers.count - 1 ? $0 + 1 : 0] }
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let webViewController = viewController as? WebViewController else {
            fatalError("viewController should be \(WebViewController.self) not \(type(of: viewController).self)")
        }

        return webViewControllers.firstIndex(of: webViewController).flatMap { self.webViewControllers[$0 > 0 ? $0 - 1 : self.webViewControllers.endIndex - 1 ] }
    }
}

extension EPUBReaderPageViewController {
    private class _PageViewController: UIPageViewController {

    }
}

