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
    private(set) var webViewConfiguration: WKWebViewConfiguration = WKWebViewConfiguration()

    lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero, configuration: self.webViewConfiguration)

        webView.uiDelegate = self
        webView.navigationDelegate = self

        return webView
    }()

    required init(configuration: WKWebViewConfiguration = .init()) {
        self.webViewConfiguration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = webView
    }
}

extension WebViewController: WKUIDelegate { }

extension WebViewController: WKNavigationDelegate { }
