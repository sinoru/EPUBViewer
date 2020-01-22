//
//  EPUBReaderWebViewController.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/21.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import UIKit
import WebKit
import EPUBKit

class EPUBReaderWebViewController: WebViewController, ObservableObject {
    static let processPool = WKProcessPool()

    @Published private(set) var isLoading: Bool = false

    weak var pageCoordinator: EPUB.PageCoordinator?
    var position: EPUB.PagePosition? {
        didSet {
            isLoading = true

            guard
                let position = self.position,
                position.pageSize == oldValue?.pageSize,
                position.itemRef == oldValue?.itemRef
            else {
                loadEPUBItem()
                return
            }

            setWebViewContentOffset(.init(x: 0, y: position.contentYOffset))
        }
    }

    required init(configuration: WKWebViewConfiguration) {
        configuration.processPool = Self.processPool
        configuration.userContentController.addUserScript(
            .init(source: String(data: NSDataAsset(name: "jQueryScript")!.data, encoding: .utf8)!, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        configuration.userContentController.addUserScript(
            .init(source: """
                $('head').append('<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0" />');
            """, injectionTime: .atDocumentEnd, forMainFrameOnly: true))

        super.init(configuration: configuration)

        webView.configuration.userContentController.add(self.weakScriptMessageHandler, name: "$")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    private func loadEPUBItem() {
        guard
            let pageCoordinator = pageCoordinator,
            let epubResourceURL = pageCoordinator.epub.resourceURL,
            let epubItem = (position?.itemRef).flatMap({ pageCoordinator.epub.items[$0] })
        else {
            webView.load(URLRequest(url: URL(string:"about:blank")!))
            return
        }

        webView.loadFileURL(epubResourceURL.appendingPathComponent(epubItem.relativePath), allowingReadAccessTo: epubResourceURL)
    }

    func setWebViewContentOffset(_ offset: CGPoint) {
        webView.evaluateJavaScript("""
            switch (document.readyState) {
                case "complete":
                    window.scrollTo(\(offset.x), \(offset.y))
                    window.webkit.messageHandlers.$.postMessage(["didScroll"])
                    break
                default:
                    window.addEventListener('load', (event) => {
                        window.scrollTo(\(offset.x), \(offset.y))
                        window.webkit.messageHandlers.$.postMessage(["didScroll"])
                    })
                    break
            }
        """, completionHandler: { (_, error) in
            debugPrint(error as Any)
        })
    }
}

extension EPUBReaderWebViewController {
    @objc
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .other, .reload:
            decisionHandler(.allow)
        default:
            decisionHandler(.cancel)
        }
    }

    @objc
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let position = position {
            setWebViewContentOffset(.init(x: 0, y: position.contentYOffset))
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
        guard let body = message.body as? [Any] else {
            return
        }

        switch body.first as? String {
        case "didScroll"?:
            isLoading = false
        default:
            break
        }
    }
}
