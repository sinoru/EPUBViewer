//
//  EPUBReaderPageViewController+SwiftUI.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/14.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import SwiftUI

extension EPUBReaderPageViewController {
    struct SwiftUIRepresentation: UIViewControllerRepresentable {
        func makeUIViewController(context: UIViewControllerRepresentableContext<EPUBReaderPageViewController.SwiftUIRepresentation>) -> EPUBReaderPageViewController {
            return EPUBReaderPageViewController()
        }

        func updateUIViewController(_ uiViewController: EPUBReaderPageViewController, context: UIViewControllerRepresentableContext<EPUBReaderPageViewController.SwiftUIRepresentation>) {

        }
    }
}
