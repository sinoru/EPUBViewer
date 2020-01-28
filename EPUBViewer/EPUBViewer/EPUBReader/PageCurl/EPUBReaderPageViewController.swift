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
    typealias WebViewController = EPUBReaderPageWebViewController
    typealias PageViewController = UIPageViewController

    private var epubMetadataObservation: AnyCancellable?
    private var epubPageCoordinatorSubscription: AnyCancellable?
    
    let epub: EPUB
    let epubPageCoordinator: EPUB.PageCoordinator

    init(epub: EPUB) {
        self.epub = epub
        self.epubPageCoordinator = epub.newPageCoordinator()

        super.init(nibName: nil, bundle: nil)

        self.epubMetadataObservation = epub.$metadata
            .sink { [weak self](metadata) in
                self?.title = [metadata.creator, metadata.title].compactMap { $0 }.joined(separator: " - ")
            }

        self.epubPageCoordinatorSubscription = epubPageCoordinator.pagePositionsPublisher
            .map(\.first)
            .compactMap({ $0 })
            .prefix(2)
            .throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: true)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    self.epubPageCoordinatorSubscription = nil
                    self.loadWebViewControllers()
                case .failure(let error):
                    debugPrint(error)
                }
            }, receiveValue: { (_) in })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    private var currentPages: [Int] = []

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

        edgesForExtendedLayout = []
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.epubPageCoordinator.pageSize = .init(width: view.bounds.size.width / 2, height: view.bounds.size.height)
        loadWebViewControllers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.epubPageCoordinator.pageSize = .init(width: view.bounds.size.width / 2, height: view.bounds.size.height)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        self.epubPageCoordinator.pageSize = .init(width: size.width / 2, height: size.height)
        updateWebViewControllers()
    }

    func updateWebViewControllers(reusableWebViewControllers: [WebViewController] = []) {
        var reusableWebViewControllers = reusableWebViewControllers

        defer {
            self.updateNextWebViewControllers(reusableWebViewControllers: &reusableWebViewControllers)
            self.updatePreviousWebViewControllers(reusableWebViewControllers: &reusableWebViewControllers)
        }

        guard
            let pageViewControllers = pageViewController.viewControllers as? [WebViewController]
        else {
            pageViewController.setViewControllers(nil, direction: .forward, animated: false)
            return
        }

        pageViewControllers.enumerated().forEach {
            $0.element.readerNavigatable = self
            $0.element.pageInfo = (epubPageCoordinator, currentPages[$0.offset])
        }
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

        guard
            let lastPosition = lastViewController.webViewController.pagePositionInfo?.1,
            let pagePositions = try? epubPageCoordinator.pagePositions.get(),
            var lastPage = pagePositions.estimatedIndex(of: lastPosition)
        else {
            nextWebViewControllers.removeAll()
            return
        }

        nextWebViewControllers.enumerated().forEach { (index, webViewController) in
            guard let webViewController = webViewController else {
                return
            }

            guard pagePositions.index(after: lastPage) < pagePositions.endIndex else {
                nextWebViewControllers[index] = nil
                return
            }

            webViewController.readerNavigatable = self
            webViewController.pageInfo = (epubPageCoordinator, pagePositions.index(after: lastPage))
            lastPage = pagePositions.index(after: lastPage)
        }
    }

    func updatePreviousWebViewControllers(reusableWebViewControllers: inout [WebViewController]) {
        var previousWebViewControllers: [WebViewController?] = self.previousWebViewControllers
        defer {
            self.previousWebViewControllers = previousWebViewControllers.compactMap({ $0 })
        }

        previousWebViewControllers.removeAll(where: {
            guard let webViewController = $0 else {
                return false
            }

            return pageViewController.viewControllers?.contains(webViewController) ?? false
        })

        guard
            let currentViewControllers = pageViewController.viewControllers as? [WebViewController],
            let firstViewController = currentViewControllers.first,
            let firstPosition = firstViewController.webViewController.pagePositionInfo?.1,
            let pagePositions = try? epubPageCoordinator.pagePositions.get(),
            var firstPage = pagePositions.estimatedIndex(of: firstPosition)
        else {
            reusableWebViewControllers += previousWebViewControllers.compactMap({ $0 })
            previousWebViewControllers.removeAll()
            return
        }

        if previousWebViewControllers.count < pageBufferSize {
            (1...(pageBufferSize - previousWebViewControllers.count)).forEach { (_) in
                previousWebViewControllers.append(reusableWebViewControllers.popLast() ?? WebViewController())
            }
        }

        previousWebViewControllers.enumerated().reversed().forEach { (index, webViewController) in
            guard let webViewController = webViewController else {
                return
            }

            guard pagePositions.index(before: firstPage) >= 0 else {
                reusableWebViewControllers += [previousWebViewControllers[index]].compactMap { $0 }
                previousWebViewControllers[index] = nil
                return
            }

            webViewController.readerNavigatable = self
            webViewController.pageInfo = (epubPageCoordinator, pagePositions.index(before: firstPage))
            firstPage = pagePositions.index(before: firstPage)
        }
    }

    func loadWebViewControllers() {
        guard isViewLoaded else {
            return
        }

        guard
            case .normal = epub.state,
            let pagePositions = try? epubPageCoordinator.pagePositions.get(),
            pagePositions.count > 2
        else {
            pageViewController.setViewControllers(nil, direction: .forward, animated: false)
            return
        }

        pageViewController.setViewControllers(
            (0..<2).map { (_) in WebViewController() },
            direction: .forward,
            animated: true
        )

        currentPages = [0, 1]
        updateWebViewControllers()
    }

}

extension EPUBReaderPageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {

    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if pageViewController.viewControllers != previousViewControllers {
            guard let previousViewControllers = previousViewControllers as? [WebViewController] else {
                fatalError("previousViewControllers should be \([WebViewController].self)")
            }

            currentPages = (pageViewController.viewControllers as? [WebViewController]).flatMap { $0.compactMap { $0.pageInfo?.1 } } ?? []
            updateWebViewControllers(reusableWebViewControllers: previousViewControllers)
        }
    }
}

extension EPUBReaderPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? WebViewController else {
            fatalError("viewController should be \([WebViewController].self)")
        }

        var reusableWebViewControllers = [WebViewController]()
        updatePreviousWebViewControllers(reusableWebViewControllers: &reusableWebViewControllers)

        let webViewController: WebViewController? = {
            guard let currentIndex = previousWebViewControllers.lastIndex(where: { $0.pageInfo?.0 == viewController.pageInfo?.0 && $0.pageInfo?.1 == viewController.pageInfo?.1 }) else {
                return previousWebViewControllers.last
            }

            guard currentIndex > 0 else {
                return nil
            }

            return previousWebViewControllers[previousWebViewControllers.index(before: currentIndex)]
        }()

        return webViewController
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? WebViewController else {
            fatalError("viewController should be \([WebViewController].self)")
        }

        var reusableWebViewControllers = [WebViewController]()
        updateNextWebViewControllers(reusableWebViewControllers: &reusableWebViewControllers)

        let webViewController: WebViewController? = {
            guard let currentIndex = nextWebViewControllers.firstIndex(where: { $0.pageInfo?.0 == viewController.pageInfo?.0 && $0.pageInfo?.1 == $0.pageInfo?.1 }) else {
                return nextWebViewControllers.first
            }

            guard nextWebViewControllers.index(after: currentIndex) < nextWebViewControllers.count else {
                return nil
            }

            return nextWebViewControllers[nextWebViewControllers.index(after: currentIndex)]
        }()

        return webViewController
    }
}

extension EPUBReaderPageViewController: EPUBReaderNavigatable {
    func navigate(to pagePosition: EPUB.PagePosition, fragment: String?) {
        guard let pagePositions = try? epubPageCoordinator.pagePositions.get() else {
            return
        }

        guard let pagePositionIndex = pagePositions.firstIndex(of: pagePosition) else {
            return
        }

        currentPages = (pagePositionIndex % 2 == 0) ? [pagePositionIndex, pagePositionIndex + 1] : [pagePositionIndex - 1, pagePositionIndex]
        updateWebViewControllers()
    }
}
