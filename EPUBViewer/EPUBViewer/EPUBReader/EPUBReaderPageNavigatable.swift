//
//  EPUBReaderPageNavigatable.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/23.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import Foundation
import EPUBKit

protocol EPUBReaderPageNavigatable {
    var epub: EPUB { get }
    var epubPageCoordinator: EPUB.PageCoordinator { get }

    func navigate(to pagePosition: EPUB.PagePosition, fragment: String?)
    func navigate(to tocItem: EPUB.TOC.Item)
}

extension EPUBReaderPageNavigatable {
    func navigate(to tocItem: EPUB.TOC.Item) {
        guard let epubItem = epub.items[tocItem.epubItemURL] else {
            return
        }

        guard let pagePositions = try? epubPageCoordinator.pagePositions.get() else {
            return
        }

        guard let pagePosition = pagePositions.first(where: { (pagePosition) in
            pagePosition.itemRef == epubItem.ref &&
                tocItem.epubItemURL.fragment.flatMap {
                    pagePosition.contentInfo.contentYOffsetsByID[$0] != nil
                } ?? true
        }) else {
            return
        }

        navigate(to: pagePosition, fragment: tocItem.epubItemURL.fragment)
    }
}
