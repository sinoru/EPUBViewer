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
    static let pageBufferSize = 2
    typealias WebViewController = EPUBReaderWebViewController
    typealias PageViewController = UIPageViewController

    var epubPageCoordinatorSubscription: AnyCancellable?
    var epub: EPUB? {
        didSet {
            guard epub !== oldValue else {
                return
            }

            self.epubPageCoordinatorSubscription = epub?.pageCoordinator.$spineItemHeights
                .throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: true)
                .sink {
                    guard let spineFirstItemRef = self.epub?.spine?.itemRefs.first else {
                        return
                    }

                    guard $0[spineFirstItemRef] != nil else {
                        return
                    }

                    self.epubPageCoordinatorSubscription = nil
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

        pageViewController.delegate = self
        pageViewController.dataSource = self

        return pageViewController
    }()

    private var previousWebViewControllers = [WebViewController]()
    private var nextWebViewControllers = [WebViewController]()

    private var pageBufferSize: Int {
        return (self.pageViewController.isDoubleSided ? Self.pageBufferSize * 2 : Self.pageBufferSize)
    }

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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        self.epub?.pageCoordinator.pageWidth = size.width / 2
        updateWebViewControllers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.epub?.pageCoordinator.pageWidth = self.view.bounds.size.width / 2
        updateWebViewControllers()
    }

    func updateWebViewControllers(reusableWebViewControllers: [WebViewController] = []) {
        var reusableWebViewControllers = reusableWebViewControllers

        self.updateNextWebViewControllers(reusableWebViewControllers: &reusableWebViewControllers)
        self.updatePreviousWebViewControllers(reusableWebViewControllers: &reusableWebViewControllers)
    }

    func updateNextWebViewControllers(reusableWebViewControllers: inout [WebViewController]) {
        var nextWebViewControllers: [WebViewController?] = self.nextWebViewControllers
        defer {
            self.nextWebViewControllers = nextWebViewControllers.compactMap({ $0 })
        }

        guard
            let currentViewControllers = pageViewController.viewControllers as? [WebViewController],
            let lastViewController = currentViewControllers.last
        else {
            nextWebViewControllers.removeAll()
            return
        }

        nextWebViewControllers.removeAll(where: {
            guard let webViewController = $0 else {
                return false
            }

            return currentViewControllers.contains(webViewController)
        })

        if nextWebViewControllers.count < pageBufferSize {
            (1...(pageBufferSize - nextWebViewControllers.count)).forEach { (_) in
                nextWebViewControllers.append(reusableWebViewControllers.popLast() ?? WebViewController())
            }
        }

        var lastPosition = lastViewController.position
        nextWebViewControllers.enumerated().forEach { (index, webViewController) in
            guard let webViewController = webViewController else {
                return
            }

            guard
                let epub = lastPosition.epub,
                let epubSpine = epub.spine,
                let epubItemRef = lastPosition.epubItemRef,
                let itemTotalHeight = try? epub.pageCoordinator.spineItemHeights[epubItemRef]?.get()
            else {
                nextWebViewControllers[index] = nil
                return
            }

            if itemTotalHeight > lastPosition.yOffset + view.bounds.height {
                webViewController.position = .init(
                    epub: lastPosition.epub,
                    epubItemRef: lastPosition.epubItemRef,
                    yOffset: lastPosition.yOffset + view.bounds.height
                )

                lastPosition = webViewController.position
            } else {
                guard let currentIndex = epubSpine.itemRefs.firstIndex(where: { $0 == epubItemRef }) else {
                    nextWebViewControllers.removeAll(where: { $0 === webViewController })
                    return
                }

                guard epubSpine.itemRefs.index(after: currentIndex) < epubSpine.itemRefs.count else {
                    nextWebViewControllers.removeAll(where: { $0 === webViewController })
                    return
                }

                webViewController.position = .init(
                    epub: lastPosition.epub,
                    epubItemRef: epubSpine.itemRefs[epubSpine.itemRefs.index(after: currentIndex)],
                    yOffset: 0
                )

                lastPosition = webViewController.position
            }
        }
    }

    func updatePreviousWebViewControllers(reusableWebViewControllers: inout [WebViewController]) {
        var previousWebViewControllers: [WebViewController?] = self.previousWebViewControllers
        defer {
            self.previousWebViewControllers = previousWebViewControllers.compactMap({ $0 })
        }

        guard
            let currentViewControllers = pageViewController.viewControllers as? [WebViewController],
            let firstViewController = currentViewControllers.first
        else {
            previousWebViewControllers.removeAll()
            return
        }

        previousWebViewControllers.removeAll(where: {
            guard let webViewController = $0 else {
                return false
            }

            return currentViewControllers.contains(webViewController)
        })

        if previousWebViewControllers.count < pageBufferSize {
            (1...(pageBufferSize - previousWebViewControllers.count)).forEach { (_) in
                previousWebViewControllers.append(reusableWebViewControllers.popLast() ?? WebViewController())
            }
        }

        var firstPosition = firstViewController.position
        previousWebViewControllers.enumerated().reversed().forEach { (index, webViewController) in
            guard let webViewController = webViewController else {
                return
            }

            guard
                let epub = firstPosition.epub,
                let epubSpine = epub.spine,
                let epubItemRef = firstPosition.epubItemRef
            else {
                previousWebViewControllers[index] = nil
                return
            }

            if firstPosition.yOffset - view.bounds.height >= 0 {
                webViewController.position = .init(
                    epub: firstPosition.epub,
                    epubItemRef: firstPosition.epubItemRef,
                    yOffset: firstPosition.yOffset - view.bounds.height
                )

                firstPosition = webViewController.position
            } else {
                guard
                    let currentIndex = epubSpine.itemRefs.lastIndex(where: { $0 == epubItemRef }),
                    currentIndex > 0
                else {
                    previousWebViewControllers.removeAll(where: { $0 === webViewController })
                    return
                }

                let epubItemRef = epubSpine.itemRefs[epubSpine.itemRefs.index(before: currentIndex)]

                guard let itemTotalHeight = try? epub.pageCoordinator.spineItemHeights[epubItemRef]?.get() else {
                    previousWebViewControllers.removeAll(where: { $0 === webViewController })
                    return
                }

                webViewController.position = .init(
                    epub: firstPosition.epub,
                    epubItemRef: epubItemRef,
                    yOffset: itemTotalHeight - view.bounds.height
                )

                firstPosition = webViewController.position
            }
        }
    }

    func loadWebViewControllers() {
        guard isViewLoaded else {
            return
        }

        guard
            let epub = epub,
            case .normal = epub.state,
            let firstSpineItemRef = epub.spine?.itemRefs.first,
            let firstSpineItemHeight = try? epub.pageCoordinator.spineItemHeights[firstSpineItemRef]?.get()
        else {
            pageViewController.setViewControllers(nil, direction: .forward, animated: false)
            return
        }

        pageViewController.setViewControllers(
            (0..<2).map {
                let webViewController = WebViewController()

                if firstSpineItemHeight < self.view.bounds.height {
                    webViewController.position = .init(
                        epub: epub,
                        epubItemRef: epub.spine?.itemRefs[$0],
                        yOffset: 0
                    )
                } else {
                    webViewController.position = .init(
                        epub: epub,
                        epubItemRef: epub.spine?.itemRefs.first,
                        yOffset: self.view.bounds.height * CGFloat($0)
                    )
                }

                return webViewController
            },
            direction: .forward,
            animated: true
        )

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
        var reusableWebViewControllers = [WebViewController]()
        updatePreviousWebViewControllers(reusableWebViewControllers: &reusableWebViewControllers)

        let webViewController: WebViewController? = {
            guard let currentIndex = previousWebViewControllers.lastIndex(where: { $0 === viewController }) else {
                return previousWebViewControllers.last
            }

            guard currentIndex > 0 else {
                return nil
            }

            return previousWebViewControllers[previousWebViewControllers.index(before: currentIndex)]
        }()

        while webViewController?.webView.isLoading == true {
            break
        }

        return webViewController
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var reusableWebViewControllers = [WebViewController]()
        updateNextWebViewControllers(reusableWebViewControllers: &reusableWebViewControllers)

        let webViewController: WebViewController? = {
            guard let currentIndex = nextWebViewControllers.firstIndex(where: { $0 === viewController }) else {
                return nextWebViewControllers.first
            }

            guard nextWebViewControllers.index(after: currentIndex) < nextWebViewControllers.count else {
                return nil
            }

            return nextWebViewControllers[nextWebViewControllers.index(after: currentIndex)]
        }()

        while webViewController?.webView.isLoading == true {
            break
        }

        return webViewController
    }
}
