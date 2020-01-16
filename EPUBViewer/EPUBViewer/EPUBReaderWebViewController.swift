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

class EPUBReaderWebViewController: WebViewController {
    static let processPool = WKProcessPool()

    override var webViewConfiguration: WKWebViewConfiguration {
        let webViewConfiguartion = WKWebViewConfiguration()
        webViewConfiguartion.processPool = Self.processPool
        webViewConfiguartion.userContentController.addUserScript(
            .init(source: String(data: NSDataAsset(name: "jQueryScript")!.data, encoding: .utf8)!, injectionTime: .atDocumentStart, forMainFrameOnly: true))

        return webViewConfiguartion
    }

    var position = Position() {
        didSet {
            self.loadEPUBItem()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        webView.isUserInteractionEnabled = false
    }

    private func loadEPUBItem() {
        guard let epub = position.epub else {
            webView.load(URLRequest(url: URL(string:"about:blank")!))
            return
        }

        guard let epubResourceURL = epub.resourceURL else {
            webView.load(URLRequest(url: URL(string:"about:blank")!))
            return
        }

        guard let epubItem = position.epubItemRef.flatMap({ epub.items?[$0] }) else {
            webView.load(URLRequest(url: URL(string:"about:blank")!))
            return
        }

        self.webView.loadFileURL(epubResourceURL.appendingPathComponent(epubItem.relativePath), allowingReadAccessTo: epubResourceURL)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        webView.evaluateJavaScript("window.scrollY") { (scrollY, _) in
            guard let scrollY = scrollY as? CGFloat else {
                return
            }


        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

extension EPUBReaderWebViewController {
    struct Position {
        var epub: EPUB?
        var epubItemRef: EPUB.Item.Ref?
        var yOffset: CGFloat = 0
    }
}

extension EPUBReaderWebViewController {
    @objc
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("window.scrollTo(0, \(position.yOffset))")
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
