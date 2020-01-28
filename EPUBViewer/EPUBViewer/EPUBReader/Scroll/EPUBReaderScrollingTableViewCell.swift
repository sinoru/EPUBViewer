//
//  EPUBReaderScrollingTableViewCell.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/21.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import UIKit
import WebKit
import EPUBKit
import Combine

class EPUBReaderScrollingTableViewCell: UITableViewCell {
    var webViewController: EPUBReaderWebViewController? {
        willSet {
            guard webViewController != newValue else {
                return
            }

            webViewController?.view.removeFromSuperview()
        }
        didSet {
            guard oldValue != webViewController else {
                return
            }

            guard let webViewController = webViewController else {
                return
            }

            webViewController.webView.scrollView.isScrollEnabled = false
            webViewController.webView.scrollView.contentInsetAdjustmentBehavior = .never

            webViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            webViewController.view.frame = contentView.bounds
            webViewController.view.backgroundColor = .clear
            contentView.addSubview(webViewController.view)
        }
    }

    var pagePositionInfo: (EPUB.PageCoordinator, EPUB.PagePosition)? {
        didSet {
            webViewController?.pagePositionInfo = pagePositionInfo
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)


    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
