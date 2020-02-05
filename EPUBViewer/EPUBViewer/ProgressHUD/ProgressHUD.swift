//
//  ProgressHUD.swift
//  EPUBViewer
//
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import SwiftUI

struct ProgressHUD<Content>: View where Content: View {
    typealias Style = ProgressHUDController.Style

    struct Controller: UIViewControllerRepresentable {
        var style: Style

        init(style: Style) {
            self.style = style
        }

        // swiftlint:disable:next line_length
        func makeUIViewController(context: UIViewControllerRepresentableContext<ProgressHUD.Controller>) -> ProgressHUDController {
            return ProgressHUDController(style: style)
        }

        // swiftlint:disable:next line_length
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
        ZStack(alignment: .center) {
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
