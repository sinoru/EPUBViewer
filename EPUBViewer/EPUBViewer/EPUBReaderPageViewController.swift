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
import Combine

class EPUBReaderPageViewController: UIViewController {
    static let pageBufferSize = 1
    typealias WebViewController = EPUBReaderWebViewController
    typealias PageViewController = UIPageViewController

    var epubStateSubscrpition: AnyCancellable?
    var epub: EPUB? {
        didSet {
            self.epubStateSubscrpition = epub?.$state
                .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
                .sink { (state) in
                    debugPrint(state)
                    self.loadWebViewControllers()
                }

            self.loadWebViewControllers()
        }
    }

    private lazy var pageViewController: PageViewController = {
        let pageViewController = PageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [.spineLocation: UIPageViewController.SpineLocation.mid.rawValue]
        )
        pageViewController.isDoubleSided = true

        return pageViewController
    }()

    private var previousWebViewControllers = [WebViewController]()
    private var nextWebViewControllers = [WebViewController]()

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        loadWebViewControllers()
    }

    func updateWebViewControllers(reusableWebViewControllers: [WebViewController] = []) {
        let currentViewController = pageViewController.viewControllers ?? []
        let isDoubleSided = pageViewController.isDoubleSided

        let pageBufferSize = (isDoubleSided ? Self.pageBufferSize * 2 : Self.pageBufferSize)

        var reusableWebViewControllers = reusableWebViewControllers

        previousWebViewControllers.removeAll(where: { currentViewController.contains($0) })
        nextWebViewControllers.removeAll(where: { currentViewController.contains($0) })

        if previousWebViewControllers.count < pageBufferSize {
            (1...(pageBufferSize - previousWebViewControllers.count)).forEach { (_) in
                previousWebViewControllers.insert(reusableWebViewControllers.popLast() ?? WebViewController(), at: 0)
            }
        }

        if nextWebViewControllers.count < pageBufferSize {
            (1...(pageBufferSize - nextWebViewControllers.count)).forEach { (_) in
                nextWebViewControllers.append(reusableWebViewControllers.popLast() ?? WebViewController())
            }
        }


    }

    func loadWebViewControllers() {
        guard isViewLoaded else {
            return
        }

        guard let epub = epub else {
            pageViewController.setViewControllers(nil, direction: .forward, animated: false)
            return
        }

        guard case .normal = epub.state else {
            pageViewController.setViewControllers(nil, direction: .forward, animated: false)
            return
        }

        let webViewControllers: [WebViewController] = (0..<2).map {
            let webViewController = WebViewController()
            webViewController.position = .init(
                epub: epub,
                epubItemRef: epub.spine?.itemRefs.first,
                yOffset: self.view.bounds.height * CGFloat($0)
            )
            return webViewController
        }

        pageViewController.setViewControllers(webViewControllers, direction: .forward, animated: false)
        updateWebViewControllers()
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
