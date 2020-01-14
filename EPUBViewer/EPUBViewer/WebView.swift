//
//  WebView.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/14.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import SwiftUI
import WebKit
import Combine

struct WebView: View {
    let configuration: WKWebViewConfiguration

    @State var request: Request?
    @Binding var isLoading: Bool

    init(configuration: WKWebViewConfiguration, request: Request?, isLoading: Binding<Bool>) {
        self._request = .init(initialValue: request)
        self._isLoading = isLoading
        self.configuration = configuration
    }
}

extension WebView {
    enum Request {
        case urlRequest(URLRequest)
    }
}

extension WebView {
    class Coordinator: NSObject {
        var subscriptions: [AnyCancellable] = []

        override init() {
            super.init()
        }
    }
}

extension WebView.Coordinator: WKUIDelegate {
    
}

extension WebView: UIViewRepresentable {
    func makeCoordinator() -> WebView.Coordinator {
        Coordinator()
    }

    func makeUIView(context: UIViewRepresentableContext<WebView>) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: configuration)

        context.coordinator.subscriptions.append(
            webView.publisher(for: \.isLoading)
                .assign(to: \.isLoading, on: self)
        )

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<WebView>) {
        switch request {
        case .urlRequest(let urlRequest)?:
            uiView.load(urlRequest)
        case nil:
            break
        }
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: WebView.Coordinator) {
        coordinator.subscriptions = []
    }
}

struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        WebView(
            configuration: WKWebViewConfiguration(),
            request: .urlRequest(URLRequest(url: URL(string: "https://www.apple.com")!)),
            isLoading: .constant(true)
        )
    }
}

