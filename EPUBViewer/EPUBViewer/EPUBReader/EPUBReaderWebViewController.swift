//
//  EPUBReaderWebViewController.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/21.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import UIKit
import WebKit
import SafariServices
import EPUBKit
import SNUXKit

class EPUBReaderWebViewController: WebViewController, ObservableObject {
    static let processPool = WKProcessPool()

    @Published private(set) var isLoading: Bool = false

    weak var readerNavigatable: (NSObjectProtocol & EPUBReaderPageNavigatable)?
    var pagePositionInfo: (EPUB.PageCoordinator, EPUB.PagePosition)? {
        didSet {
            isLoading = true

            guard
                let position = self.pagePositionInfo,
                position.1.pageSize == oldValue?.1.pageSize,
                position.1.itemRef == oldValue?.1.itemRef
            else {
                loadEPUBItem()
                return
            }

            setWebViewContentOffset(.init(x: 0, y: position.1.contentYOffset))
        }
    }

    var itemRef: EPUB.Item.Ref? {
        pagePositionInfo?.1.itemRef
    }
    private(set) var fragment: String?

    required init(configuration: WKWebViewConfiguration) {
        configuration.processPool = Self.processPool
        configuration.userContentController.addUserScript(
            .init(source: String(data: NSDataAsset(name: "jQueryScript")!.data, encoding: .utf8)!, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        configuration.userContentController.addUserScript(
            .init(source: """
                $('head').append('<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0" />')
            """, injectionTime: .atDocumentEnd, forMainFrameOnly: true))

        super.init(configuration: configuration)

        webView.configuration.userContentController.add(self.weakScriptMessageHandler, name: "$")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "$")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @discardableResult
    override func present(error: Error) -> Bool {
        guard
            let error = error as? URLError,
            error.code != URLError.cancelled else {
                return false
        }

        return super.present(error: error)
    }

    private func loadEPUBItem() {
        guard
            let pageCoordinator = pagePositionInfo?.0,
            let epubResourceURL = pageCoordinator.epub.resourceURL,
            let epubItem = (pagePositionInfo?.1.itemRef).flatMap({ pageCoordinator.epub.items[$0] })
        else {
            webView.load(URLRequest(url: URL(string: "about:blank")!))
            return
        }

        webView.loadFileURL(epubResourceURL.appendingPathComponent(epubItem.url.relativePath), allowingReadAccessTo: epubResourceURL)
    }

    func setWebViewContentOffset(_ offset: CGPoint) {
        // swiftlint:disable line_length
        webView.evaluateJavaScript("""
            function windowDidLoad() {
                if (location.href == "about:blank") {
                    return
                }

                window.scrollTo(\(offset.x), \(offset.y))

                const identifiableElements = $('*[id]')

                const nearestElement = identifiableElements.filter((i, v) => v.getBoundingClientRect().y <= 0).sort((a, b) => Math.abs(a.getBoundingClientRect().y) - Math.abs(b.getBoundingClientRect().y)).get(0)

                if (nearestElement != null) {
                    window.webkit.messageHandlers.$.postMessage(["didScroll", nearestElement.id])
                } else {
                    window.webkit.messageHandlers.$.postMessage(["didScroll"])
                }
            }

            switch (document.readyState) {
                case "complete":
                    windowDidLoad()
                    break
                default:
                    window.addEventListener('load', (event) => {
                        windowDidLoad()
                    })
                    break
            }
        """, completionHandler: { (_, error) in
            if let error = error {
                self.present(error: error)
            }
        })
        // swiftlint:enable line_length
    }
}

extension EPUBReaderWebViewController {
    @objc
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .linkActivated, .formSubmitted, .formResubmitted:
            break
        default:
            decisionHandler(.allow)
            return
        }

        guard
            let originalURL = webView.url,
            let targetURL = navigationAction.request.url else {
                decisionHandler(.allow)
                return
        }

        guard navigationAction.targetFrame?.isMainFrame == true else {
            decisionHandler(.allow)
            return
        }

        guard originalURL != targetURL else {
            decisionHandler(.allow)
            return
        }

        guard originalURL.scheme != "about" else {
            decisionHandler(.allow)
            return
        }

        guard
            originalURL.scheme == targetURL.scheme,
            originalURL.host == targetURL.host,
            originalURL.port == targetURL.port else {
                decisionHandler(.cancel)
                present(SFSafariViewController(url: targetURL), animated: true)
                return
        }

        guard let pagePositionInfo = pagePositionInfo else {
            decisionHandler(.cancel)
            return
        }

        let pageCoordinator = pagePositionInfo.0
        let epub = pageCoordinator.epub

        guard let epubResourceURL = epub.resourceURL else {
            decisionHandler(.cancel)
            return
        }

        guard let item = epub.items.first(where: { URL(fileURLWithPath: $0.url.relativePath, relativeTo: epubResourceURL).path == targetURL.path }) else {
            decisionHandler(.cancel)
            return
        }

        let pagePositions: [EPUB.PagePosition?] = pageCoordinator.pagePositions.flatten()

        guard let pagePosition = pagePositions.lazy
            .filter({ $0?.itemRef == item.ref })
            .first(where: {
                if let fragment = targetURL.fragment {
                    return $0?.contentInfo.contentYOffsetsByID.contains(where: { $0.key == fragment }) == true
                } else {
                    return true
                }
            }) as? EPUB.PagePosition else {
                decisionHandler(.cancel)
                return
        }

        readerNavigatable?.navigate(to: pagePosition, fragment: targetURL.fragment)
        decisionHandler(.cancel)
    }

    @objc
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let position = pagePositionInfo?.1 {
            setWebViewContentOffset(.init(x: 0, y: position.contentYOffset))
        }
    }

    @objc
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        present(error: error)
    }

    @objc
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        present(error: error)
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

            fragment = body.indices.contains(1) ? body[1] as? String : nil
        default:
            break
        }
    }
}
