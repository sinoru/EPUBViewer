//
//  DocumentView.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/03.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import SwiftUI

struct DocumentView: View {
    var document: UIDocument
    var dismiss: () -> Void

    var body: some View {
        VStack {
            HStack {
                Text("File Name")
                    .foregroundColor(.secondary)

                Text(document.fileURL.lastPathComponent)
            }

            Button("Done", action: dismiss)
        }
    }
}
