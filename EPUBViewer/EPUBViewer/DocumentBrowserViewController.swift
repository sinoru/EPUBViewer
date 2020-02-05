//
//  DocumentBrowserViewController.swift
//  EPUBViewer
//
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import EPUBKit
import SwiftUI
import UIKit

class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        
        allowsDocumentCreation = false
        allowsPickingMultipleItems = false
        
        // Update the style of the UIDocumentBrowserViewController
        // browserUserInterfaceStyle = .dark
        // view.tintColor = .white
        
        // Specify the allowed content types of your application via the Info.plist.
        
        // Do any additional setup after loading the view.
    }
    
    
    // MARK: UIDocumentBrowserViewControllerDelegate

    // swiftlint:disable:next line_length
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        let newDocumentURL: URL? = nil
        
        // Set the URL for the new document here. Optionally, you can present a template chooser before calling the importHandler.
        // Make sure the importHandler is always called, even if the user cancels the creation request.
        if newDocumentURL != nil {
            importHandler(newDocumentURL, .move)
        } else {
            importHandler(nil, .none)
        }
    }

    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        guard let sourceURL = documentURLs.first else { return }
        
        // Present the Document View Controller for the first document that was picked.
        // If you support picking multiple items, make sure you handle them all.
        previewEPUB(at: sourceURL)
    }

    // swiftlint:disable:next line_length
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
        previewEPUB(at: destinationURL)
    }

    // swiftlint:disable:next line_length
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }

    // MARK: EPUB Preview

    func previewEPUB(at fileURL: URL) {
        do {
            let epub = try EPUB(fileURL: fileURL)

            let epubPrewviewView = EPUBPreviewView(dismiss: {
                self.dismiss(animated: true)
            }, open: {
                self.dismiss(animated: true) {
                    self.openEPUB(epub)
                }
            })
            .environmentObject(epub)

            let epubPrewviewViewController = UIHostingController(rootView: epubPrewviewView)
            self.present(epubPrewviewViewController, animated: true, completion: nil)
        } catch {
            present(error: error)
        }
    }

    func openEPUB(_ epub: EPUB) {
        let epubReaderViewController = EPUBReaderViewController(
            epub: epub,
            dismiss: {
                self.dismiss(animated: true)
            })
        epubReaderViewController.modalPresentationStyle = .fullScreen

        self.present(epubReaderViewController, animated: true)
    }
}
