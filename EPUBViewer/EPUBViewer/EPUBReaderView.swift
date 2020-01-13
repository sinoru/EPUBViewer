//
//  EPUBReaderView.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/13.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import SwiftUI
import EPUBKit

struct EPUBReaderView: View {
    @EnvironmentObject var epub: EPUB
    var dismiss: () -> Void
    
    var body: some View {
        EPUBReaderView.ContentsView(title: epub.metadata?.title)
    }
}

extension EPUBReaderView {
    struct ContentsView: View {
        @State var title: String?

        var body: some View {
            NavigationView {
                VStack {
                    HStack {
                        Text("Hello, World!")
                    }
                }
                .navigationBarTitle(Text(title ?? ""), displayMode: .inline)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

struct EPUBReaderView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["iPhone SE", "iPhone 11 Pro", "iPad Pro (11-inch)"], id: \.self) { deviceName in
            EPUBReaderView.ContentsView(
                title: "A Title"
            )
                .previewDevice(PreviewDevice(rawValue: deviceName))
                .previewDisplayName(deviceName)
        }
    }
}
