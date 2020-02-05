//
//  EPUBReaderOptionsView.swift
//  EPUBViewer
//
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import SwiftUI

struct EPUBReaderOptionsView: View {
    @Binding var options: EPUBReaderOptions

    var body: some View {
        NavigationView {
            List {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Reader Mode").bold()

                    Picker("Reader Mode", selection: $options.readerMode) {
                        ForEach(EPUBReaderOptions.ReaderMode.allCases, id: \.self) { readerMode in
                            Text(readerMode.description).tag(readerMode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationBarTitle("Options")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct EPUBReaderOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        EPUBReaderOptionsView(options: .constant(.init()))
    }
}
