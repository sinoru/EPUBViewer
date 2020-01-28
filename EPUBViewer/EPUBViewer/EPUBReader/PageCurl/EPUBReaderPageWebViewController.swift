//
//  EPUBReaderPageWebViewController.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/15.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import UIKit
import WebKit
import EPUBKit
import Combine

class EPUBReaderPageWebViewController: UIViewController {
    private(set) lazy var webViewController: EPUBReaderWebViewController = .init(configuration: .init())

    var pageInfo: (EPUB.PageCoordinator, Int)? {
        didSet {
            webViewController.pagePositionInfo = pageInfo
                .flatMap { try? ($0.0, $0.0.pagePositions.get()[$0.1]) }
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
            .sink(receiveValue: { [weak self](isLoading) in
                self?.webViewController.webView.isHidden = isLoading
            })
    }
}
