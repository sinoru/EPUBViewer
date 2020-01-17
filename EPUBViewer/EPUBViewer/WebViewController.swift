//
//  WebViewController.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/15.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {
    var webViewConfiguration: WKWebViewConfiguration {
        return WKWebViewConfiguration()
    }

    lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero, configuration: self.webViewConfiguration)

        webView.uiDelegate = self
        webView.navigationDelegate = self

        return webView
    }()

    override func loadView() {
        view = webView
    }
}

extension WebViewController: WKUIDelegate { }

extension WebViewController: WKNavigationDelegate { }
