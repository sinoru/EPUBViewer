//
//  EPUBReaderPageWebViewController.swift
//  EPUBViewer
//
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import Combine
import EPUBKit
import UIKit
import WebKit

class EPUBReaderPageWebViewController: UIViewController {
    private(set) lazy var webViewController: EPUBReaderWebViewController = .init(configuration: .init())

    weak var readerNavigatable: (NSObjectProtocol & EPUBReaderPageNavigatable)? {
        didSet {
            webViewController.readerNavigatable = readerNavigatable
        }
    }
    var pageInfo: (EPUB.PageCoordinator, Int)? {
        didSet {
            guard let pageInfo = pageInfo else {
                webViewController.pagePositionInfo = nil
                return
            }

            let pagePositions: [EPUB.PagePosition?] = pageInfo.0.pagePositions.flatten()

            guard pagePositions.indices.contains(pageInfo.1) else {
                webViewController.pagePositionInfo = nil
                return
            }

            guard !pagePositions[0...pageInfo.1].contains(nil) else {
                return
            }

            guard let pagePosition = pagePositions[pageInfo.1] else {
                return
            }

            webViewController.pagePositionInfo = (pageInfo.0, pagePosition)
        }
    }

    private var loadingObserver: AnyCancellable?

    private(set) var isLoading: Bool = false {
        didSet {
            webViewController.webView.isHidden = isLoading
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        webViewController.webView.scrollView.isScrollEnabled = false

        addChild(webViewController)

        webViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webViewController.view.frame = view.bounds
        webViewController.view.backgroundColor = .clear
        view.addSubview(webViewController.view)

        loadingObserver = webViewController.$isLoading
            .sink(receiveValue: { [weak self]isLoading in
                self?.webViewController.webView.isHidden = isLoading
            })
    }
}
