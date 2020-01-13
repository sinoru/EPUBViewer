//
//  EPUBPreviewView.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/13.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import SwiftUI
import EPUBKit

struct EPUBPreviewView: View {
    @EnvironmentObject var epub: EPUB

    var dismiss: () -> Void
    var open: () -> Void

    var body: some View {
        ContentsView(
            title: epub.metadata?.title,
            creator: epub.metadata?.creator,
            filename: epub.epubFileURL.lastPathComponent,
            dismiss: dismiss,
            open: open
        )
    }
}

extension EPUBPreviewView {
    struct ContentsView: View {
        var title: String?
        var creator: String?
        var filename: String

        var dismiss: () -> Void
        var open: () -> Void

        var body: some View {
            NavigationView {
                VStack {
                    Spacer()
                    VStack {
                        HStack {
                            Text("Title")
                                .foregroundColor(.secondary)

                            Text(title ?? "")
                        }
                        HStack {
                            Text("Creator")
                                .foregroundColor(.secondary)

                            Text(creator ?? "")
                        }
                    }
                    Spacer()
                    Button("Open", action: open)
                }
                .navigationBarTitle(filename)
                .navigationBarItems(trailing: Button("Done", action: dismiss))
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

struct EPUBPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        EPUBPreviewView.ContentsView(
            title: "A Title",
            creator: "The Creator",
            filename: "The filename",
            dismiss: {},
            open: {}
        )
    }
}
