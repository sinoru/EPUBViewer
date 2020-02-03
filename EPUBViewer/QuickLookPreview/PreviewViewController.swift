//
//  PreviewViewController.swift
//  QuickLookPreview
//
//  Created by Jaehong Kang on 2020/01/10.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import Combine
import EPUBKit
import QuickLook
import UIKit

class PreviewViewController: UIViewController, QLPreviewingController {
        
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var creatorLabel: UILabel!

    var epub: EPUB?
    var epubStateObserver: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    /*
     * Implement this method and set QLSupportsSearchableItems to YES in the Info.plist of the extension if you support CoreSpotlight.
     *
    func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping (Error?) -> Void) {
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        handler(nil)
    }
    */
    

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        // Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.

        // Perform any setup necessary in order to prepare the view.
        do {
            epub = try EPUB(fileURL: url)

            epubStateObserver = epub?.$state
                .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
                .sink { state in
                    if case .error(let error) = state {
                        handler(error)
                        return
                    }

                    guard case .closed = state else {
                        return
                    }

                    self.titleLabel.text = self.epub?.metadata.title
                    self.creatorLabel.text = self.epub?.metadata.creator

                    // Call the completion handler so Quick Look knows that the preview is fully loaded.
                    // Quick Look will display a loading spinner while the completion handler is not called.
                    handler(nil)
                }
        } catch {
            handler(error)
        }
    }
}
