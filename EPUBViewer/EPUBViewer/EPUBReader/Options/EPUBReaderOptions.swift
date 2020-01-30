//
//  EPUBReaderOptions.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/21.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import Foundation

struct EPUBReaderOptions {
    enum ReaderMode: CaseIterable {
        case pageCurl
        case scroll
    }

    var readerMode: ReaderMode = .pageCurl
}

extension EPUBReaderOptions.ReaderMode: CustomStringConvertible {
    var description: String {
        switch self {
        case .pageCurl:
            return "Page Curl"
        case .scroll:
            return "Scroll"
        }
    }
}
