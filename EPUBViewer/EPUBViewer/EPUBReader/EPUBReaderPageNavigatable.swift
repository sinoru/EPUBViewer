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

    var navigationInfo: (epubItemRef: EPUB.Item.Ref, fragment: String?)? { get }

    func navigate(to pagePosition: EPUB.PagePosition, fragment: String?)
    func navigate(to tocItem: EPUB.TOC.Item)
    func navigate(to epubItemRef: EPUB.Item.Ref, fragment: String?)
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
            if epubPageCoordinator.progress.fractionCompleted < 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.navigate(to: tocItem)
                }
            }
            return
        }

        navigate(to: pagePosition, fragment: tocItem.epubItemURL.fragment)
    }

    func navigate(to epubItemRef: EPUB.Item.Ref, fragment: String?) {
        guard let epubItem = epub.items[epubItemRef] else {
            return
        }

        guard let pagePositions = try? epubPageCoordinator.pagePositions.get() else {
            return
        }

        guard let pagePosition = pagePositions.first(where: { (pagePosition) in
            pagePosition.itemRef == epubItem.ref &&
                fragment.flatMap {
                    pagePosition.contentInfo.contentYOffsetsByID[$0] != nil
                } ?? true
        }) else {
            if epubPageCoordinator.progress.fractionCompleted < 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.navigate(to: epubItemRef, fragment: fragment)
                }
            }
            return
        }

        navigate(to: pagePosition, fragment: fragment)
    }
}
