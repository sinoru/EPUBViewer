//
//  EPUBReaderWebViewController.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/15.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import UIKit
import WebKit
import EPUBKit

class EPUBReaderWebViewController: UIViewController {
    static let processPool = WKProcessPool()

    private lazy var webViewController: WebViewController = WebViewController(configuration: {
        let webViewConfiguartion = WKWebViewConfiguration()
        webViewConfiguartion.processPool = Self.processPool
        webViewConfiguartion.userContentController.add(self, name: "$")

        return webViewConfiguartion
    }())

    var pageCoordinator: EPUB.PageCoordinator?
    var page: Int? {
        didSet {
            position = page.flatMap { pageCoordinator.flatMap { try? $0.pagePositions.get() }?[$0] }
        }
    }

    private(set) var isLoading: Bool = false {
        didSet {
            webViewController.webView.isHidden = isLoading
        }
    }

    private(set) var position: EPUB.PageCoordinator.PagePosition? {
        didSet {
            isLoading = true

            guard
                let position = self.position,
                position.coordinator == oldValue?.coordinator && position.epubItemRef == oldValue?.epubItemRef
            else {
                loadEPUBItem()
                return
            }

            setWebViewContentOffset(.init(x: 0, y: position.yOffset))
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        webViewController.webView.navigationDelegate = self
        webViewController.webView.scrollView.isScrollEnabled = false

        addChild(webViewController)

        webViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webViewController.view.frame = view.bounds
        view.addSubview(webViewController.view)
    }

    private func loadEPUBItem() {
        guard
            let pageCoordinator = position?.coordinator,
            let epub = pageCoordinator.epub,
            let epubResourceURL = epub.resourceURL,
            let epubItem = (position?.epubItemRef).flatMap({ epub.items?[$0] })
        else {
            webViewController.webView.load(URLRequest(url: URL(string:"about:blank")!))
            return
        }

        webViewController.webView.loadFileURL(epubResourceURL.appendingPathComponent(epubItem.relativePath), allowingReadAccessTo: epubResourceURL)
    }

    func setWebViewContentOffset(_ offset: CGPoint) {
        webViewController.webView.evaluateJavaScript("""
            switch (document.readyState) {
                case "complete":
                    window.scrollTo(\(offset.x), \(offset.y))
                    window.webkit.messageHandlers.$.postMessage(null)
                    break
                default:
                    window.addEventListener('load', (event) => {
                        window.scrollTo(\(offset.x), \(offset.y))
                        window.webkit.messageHandlers.$.postMessage(null)
                    })
                    break
            }
        """, completionHandler: { (_, error) in
            debugPrint(error as Any)
        })
    }
}

extension EPUBReaderWebViewController: WKNavigationDelegate {
    @objc
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let position = position {
            setWebViewContentOffset(.init(x: 0, y: position.yOffset))
        }
    }

    @objc
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        debugPrint(error)
    }

    @objc
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        debugPrint(error)
    }
}

extension EPUBReaderWebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        isLoading = false
    }
}
