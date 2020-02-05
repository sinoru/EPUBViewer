//
//  AppDelegate.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/03.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // swiftlint:disable:next line_length
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // swiftlint:disable line_length
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        // swiftlint:enable line_length
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // swiftlint:disable line_length
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // swiftlint:enable line_length
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // swiftlint:disable line_length
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        // swiftlint:enable line_length
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // swiftlint:disable line_length
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        // swiftlint:enable line_length
    }

    // swiftlint:disable:next line_length
    func application(_ app: UIApplication, open inputURL: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Ensure the URL is a file URL
        guard inputURL.isFileURL else { return false }
                
        // Reveal / import the document at the URL
        guard let documentBrowserViewController = window?.rootViewController as? DocumentBrowserViewController else { return false }

        documentBrowserViewController.revealDocument(at: inputURL, importIfNeeded: true) { revealedDocumentURL, error in
            if let error = error {
                // Handle the error appropriately
                print("Failed to reveal the document at URL \(inputURL) with error: '\(error)'")
                return
            }
            
            // Present the Document View Controller for the revealed URL
            documentBrowserViewController.previewEPUB(at: revealedDocumentURL!)
        }

        return true
    }


}
