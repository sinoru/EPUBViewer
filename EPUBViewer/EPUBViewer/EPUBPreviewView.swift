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

    @State private var error: Error?

    var body: some View {
        NavigationView {
            ContentsView(
                title: epub.metadata?.title,
                creator: epub.metadata?.creator,
                filename: epub.epubFileURL.lastPathComponent,
                dismiss: dismiss,
                open: open
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onReceive(epub.$state) {
            if case .error(let error) = $0 {
                self.error = error
            }
        }
        .alert(isPresented: .constant(error != nil)) {
            Alert(
                title: Text("Error"),
                message: error.flatMap { Text($0.localizedDescription) },
                dismissButton: .default(Text("Confirm")) {
                    self.dismiss()
                }
            )
        }
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
    }
}

struct EPUBPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EPUBPreviewView.ContentsView(
                title: "A Title",
                creator: "The Creator",
                filename: "The filename",
                dismiss: {},
                open: {}
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
