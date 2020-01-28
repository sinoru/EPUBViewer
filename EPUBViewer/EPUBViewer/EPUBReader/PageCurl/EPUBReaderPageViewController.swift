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
    private var epubPageCoordinatorFirstLoadSubscription: AnyCancellable?
    private var epubPageCoordinatorSubscription: AnyCancellable?
    
    let epub: EPUB
    let epubPageCoordinator: EPUB.PageCoordinator

    lazy var slider: UISlider = {
        let slider = UISlider()

        slider.addTarget(self, action: #selector(self.sliderValueDidChange), for: .valueChanged)
        slider.isContinuous = false

        return slider
    }()

    init(epub: EPUB) {
        self.epub = epub
        self.epubPageCoordinator = epub.newPageCoordinator()

        super.init(nibName: nil, bundle: nil)

        self.epubMetadataObservation = epub.$metadata
            .sink { [weak self](metadata) in
                self?.title = [metadata.creator, metadata.title].compactMap { $0 }.joined(separator: " - ")
            }

        self.epubPageCoordinatorSubscription = epubPageCoordinator.pagePositionsPublisher
            .throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: true)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    debugPrint(error)
                }
            }, receiveValue: { [unowned self](pagePositions) in
                self.slider.maximumValue = Float(pagePositions.count)
            })

        self.epubPageCoordinatorFirstLoadSubscription = epubPageCoordinator.pagePositionsPublisher
            .removeDuplicates()
            .map(\.count)
            .delay(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    debugPrint(error)
                }
            }, receiveValue: { [unowned self](count) in
                if (self.pageViewController.viewControllers as? [WebViewController])?.first?.webViewController.pagePositionInfo == nil {
                    self.loadWebViewControllers()
                }
            })
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

    private var pageSize: Int {
        return pageViewController.isDoubleSided ? 2 : 1
    }

    private var pageBufferSize: Int {
        return Self.pageBufferSize * pageSize
    }

    private var currentPage: Int = 0 {
        didSet {
            slider.value = Float(currentPage)
        }
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

        pageViewController.setViewControllers((0..<pageSize).map { (_) in WebViewController() }, direction: .forward, animated: false)

        edgesForExtendedLayout = []

        toolbarItems = [
            .init(customView: slider)
        ]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.epubPageCoordinator.pageSize = .init(width: view.bounds.size.width / CGFloat(pageSize), height: view.bounds.size.height)
        loadWebViewControllers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.epubPageCoordinator.pageSize = .init(width: view.bounds.size.width / CGFloat(pageSize), height: view.bounds.size.height)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        self.epubPageCoordinator.pageSize = .init(width: size.width / CGFloat(pageSize), height: size.height)
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
            pageViewController.setViewControllers((0..<pageSize).map { (_) in WebViewController() }, direction: .forward, animated: false)
            return
        }

        pageViewControllers.enumerated().forEach {
            $0.element.readerNavigatable = self
            $0.element.pageInfo = (epubPageCoordinator, currentPage + $0.offset)
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

            guard pagePositions.indices.contains(pagePositions.index(after: lastPage)) else {
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

            guard pagePositions.indices.contains(pagePositions.index(before: firstPage)) else {
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
            pagePositions.count > pageSize
        else {
            pageViewController.setViewControllers((0..<pageSize).map { (_) in WebViewController() }, direction: .forward, animated: false)
            return
        }

        pageViewController.setViewControllers(
            (0..<pageSize).map { (_) in WebViewController() },
            direction: .forward,
            animated: false
        )

        currentPage = 0
        updateWebViewControllers()
    }

    @IBAction
    func sliderValueDidChange(_ sender: UISlider) {
        let page = Int(min(sender.value.rounded(), sender.maximumValue))

        guard let pagePosition = try? epubPageCoordinator.pagePositions.get()[page] else {
            return
        }

        navigate(to: pagePosition, fragment: nil)
    }
}

extension EPUBReaderPageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewController.SpineLocation {
        switch (pageViewController.traitCollection.userInterfaceIdiom, orientation) {
        case (.phone, .landscapeLeft), (.phone, .landscapeRight), (.pad, _):
            pageViewController.isDoubleSided = true
            pageViewController.setViewControllers(
                (pageViewController.viewControllers?[0]).flatMap { [$0, WebViewController()] } ?? (0..<pageSize).map { (_) in WebViewController() },
                direction: .forward,
                animated: true)

            return .mid
        default:
            pageViewController.isDoubleSided = false
            pageViewController.setViewControllers(
                (pageViewController.viewControllers?[0]).flatMap { [$0] } ?? (0..<pageSize).map { (_) in WebViewController() },
                direction: .forward,
                animated: true)

            return .min
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {

    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if pageViewController.viewControllers != previousViewControllers {
            guard let previousViewControllers = previousViewControllers as? [WebViewController] else {
                fatalError("previousViewControllers should be \([WebViewController].self)")
            }

            currentPage = (pageViewController.viewControllers as? [WebViewController])?.first?.pageInfo?.1 ?? 0
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
            guard let currentIndex = nextWebViewControllers.firstIndex(where: { $0.pageInfo?.0 == viewController.pageInfo?.0 && $0.pageInfo?.1 == viewController.pageInfo?.1 }) else {
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

extension EPUBReaderPageViewController: EPUBReaderPageNavigatable {
    func navigate(to pagePosition: EPUB.PagePosition, fragment: String?) {
        guard let pagePositions = try? epubPageCoordinator.pagePositions.get() else {
            return
        }

        guard let pagePositionIndex = pagePositions.firstIndex(of: pagePosition) else {
            return
        }

        currentPage = (pagePositionIndex % 2 == 0) ? pagePositionIndex : pagePositionIndex - 1
        updateWebViewControllers()
    }
}
