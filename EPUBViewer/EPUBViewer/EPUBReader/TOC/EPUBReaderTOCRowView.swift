//
//  EPUBReaderTOCRowView.swift
//  EPUBViewer
//
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import SwiftUI

struct EPUBReaderTOCRowView: View {
    var depth: Int
    var name: String

    var body: some View {
        Text(name)
            .padding(.leading, CGFloat(depth) * 16)
    }
}

struct EPUBReaderTOCRowView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            EPUBReaderTOCRowView(depth: 0, name: "Test Depth 0")
            EPUBReaderTOCRowView(depth: 1, name: "Test Depth 1")
            EPUBReaderTOCRowView(depth: 2, name: "Test Depth 2")
            EPUBReaderTOCRowView(depth: 1, name: "Test Depth 1")
            EPUBReaderTOCRowView(depth: 0, name: "Test Depth 0")
        }
    }
}
