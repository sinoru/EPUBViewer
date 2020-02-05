//
//  EPUBReaderTOCView.swift
//  EPUBViewer
//
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import EPUBKit
import SwiftUI

struct EPUBReaderTOCView: View {
    @EnvironmentObject var epub: EPUB

    var didSelect: (EPUB.TOC.Item) -> Void

    var body: some View {
        epub.toc.flatMap { toc in
            List(toc.flattenKeyPaths(), id: \.playOrder) { depth, _, keyPath in
                Button(action: {
                    self.didSelect(toc[keyPath: keyPath])
                }) {
                    EPUBReaderTOCRowView(depth: depth, name: toc[keyPath: keyPath].name)
                }
            }
        }
    }
}
