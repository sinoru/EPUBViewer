//
//  EPUBReaderViewController.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/20.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import UIKit
import EPUBKit
import Combine
import SwiftUI

class EPUBReaderViewController: UINavigationController {
    let epub: EPUB
    let dismissHandler: () -> Void

    private var options: EPUBReaderOptions = .init() {
        didSet {
            if options.readerMode != oldValue.readerMode {
                let viewController: UIViewController = {
                    switch options.readerMode {
                    case .pageCurl:
                        return EPUBReaderPageViewController(epub: epub)
                    case .scroll:
                        return EPUBReaderScrollingTableViewController(epub: epub)
                    }
                }()

                self.setViewControllers([viewController], animated: true)
            }
        }
    }
    private var epubStateObservation: AnyCancellable?

    init(epub: EPUB, dismiss: @escaping () -> Void) {
        self.epub = epub
        self.dismissHandler = dismiss

        super.init(rootViewController: EPUBReaderScrollingTableViewController(epub: epub))

        self.delegate = self
        self.epubStateObservation = epub.$state
            .throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: true)
            .sink { [weak self](_) in
                self?.openEPUB()
            }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        hidesBarsOnTap = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        openEPUB()
    }

    @IBAction
    func close() {
        dismissHandler()
    }

    func openEPUB() {
        guard
            case .closed = epub.state,
            view.window != nil
        else {
            return
        }

        let progressHUDController = ProgressHUDController.init(style: .dark)
        self.present(progressHUDController, animated: true)

        epub.open { (result) in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    progressHUDController.dismiss(animated: true)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    progressHUDController.dismiss(animated: true) {
                        let alertController = UIAlertController.init(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                        alertController.addAction(
                            .init(title: "Confirm", style: .default)
                        )

                        self.present(alertController, animated: true)
                    }
                }
            }
        }
    }

    @IBAction
    func presentTOC(_ sender: UIBarButtonItem?) {
        let epubReaderTOCView = EPUBReaderTOCView() { (toc) in
            self.dismiss(animated: true)
        }.environmentObject(epub)

        let epubReaderTOCViewController = UIHostingController(rootView: epubReaderTOCView)
        epubReaderTOCViewController.modalPresentationStyle = .popover
        epubReaderTOCViewController.popoverPresentationController?.barButtonItem = sender

        self.present(epubReaderTOCViewController, animated: true)
    }

    @IBAction
    func presentOptions(_ sender: UIBarButtonItem?) {
        let epubReaderOptionsView = EPUBReaderOptionsView(
            options: .init(get: { self.options }, set: { self.options = $0 })
        )

        let epubReaderOptionsViewController = UIHostingController(rootView: epubReaderOptionsView)
        epubReaderOptionsViewController.modalPresentationStyle = .popover
        epubReaderOptionsViewController.popoverPresentationController?.barButtonItem = sender

        self.present(epubReaderOptionsViewController, animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


extension EPUBReaderViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        viewController.navigationItem.leftBarButtonItems = [
            .init(barButtonSystemItem: .close, target: self, action: #selector(self.close)),
            .init(title: "TOC", style: .plain, target: self, action: #selector(self.presentTOC))
        ]
        viewController.navigationItem.rightBarButtonItems = [
            .init(title: "Options", style: .plain, target: self, action: #selector(self.presentOptions))
        ]
    }
}
