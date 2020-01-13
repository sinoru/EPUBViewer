//
//  DocumentBrowserViewController.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/03.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import UIKit
import SwiftUI
import EPUBKit

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
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
        previewEPUB(at: destinationURL)
    }
    
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
                self.openEPUB(epub)
            })
            .environmentObject(epub)

            let epubPrewviewViewController = UIHostingController(rootView: epubPrewviewView)
            self.present(epubPrewviewViewController, animated: true, completion: nil)
        } catch {
            self.presentError(error)
        }
    }

    func openEPUB(_ epub: EPUB) {

    }

    // MAKR: -

    func presentError(_ error: Swift.Error) {
        debugPrint(error)
    }
    
    // MARK: Document Presentation
    
    func presentDocument(at documentURL: URL) {
        let document = Document(fileURL: documentURL)

        // Access the document
        document.open(completionHandler: { success in
            if success {
                // Display the content of the document:
                let view = DocumentView(document: document, dismiss: {
                    self.closeDocument(document)
                })

                let documentViewController = UIHostingController(rootView: view)
                self.present(documentViewController, animated: true, completion: nil)
            } else {
                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
            }
        })
    }

    func closeDocument(_ document: Document) {
        dismiss(animated: true) {
            document.close(completionHandler: nil)
        }
    }
}

