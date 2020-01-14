//
//  ProgressHUD.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/14.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import SwiftUI

struct ProgressHUD<Content> : View where Content : View {
    typealias Style = ProgressHUDController.Style

    struct Controller: UIViewControllerRepresentable {
        var style: Style

        init(style: Style) {
            self.style = style
        }

        func makeUIViewController(context: UIViewControllerRepresentableContext<ProgressHUD.Controller>) -> ProgressHUDController {
            return ProgressHUDController(style: style)
        }

        func updateUIViewController(_ uiViewController: ProgressHUDController, context: UIViewControllerRepresentableContext<ProgressHUD.Controller>) {

        }
    }

    struct View: SwiftUI.View {
        var style: Style

        init(style: Style) {
            self.style = style
        }

        var body: some SwiftUI.View {
            Controller(style: style)
        }
    }

    let style: Style
    var content: Content
    @Binding var isPresented: Bool

    init(style: Style, isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.style = style
        self._isPresented = isPresented
        self.content = content()
    }

    var body: some SwiftUI.View {
        ZStack {
            content
            if isPresented {
                View(style: style)
            }
        }
    }
}

struct ProgressHUD_Previews: PreviewProvider {
    static var previews: some View {
        ProgressHUD<EmptyView>.View(style: .dark)
    }
}
