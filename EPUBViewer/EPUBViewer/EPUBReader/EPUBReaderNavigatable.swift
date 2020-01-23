//
//  EPUBReaderNavigatable.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/23.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import Foundation
import EPUBKit

protocol EPUBReaderNavigatable {
    func navigate(to tocItem: EPUB.TOC.Item)
}
