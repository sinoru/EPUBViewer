//
//  EPUBReaderScrollingTableViewController.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/21.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import UIKit
import EPUBKit
import Combine

class EPUBReaderScrollingTableViewController: UITableViewController {
    enum Section: CaseIterable {
        case main
    }

    static let cellReuseIdentifier = "Cell"

    private var epubMetadataObservation: AnyCancellable?
    private var epubPageCoordinatorSubscription: AnyCancellable?

    let epub: EPUB
    let epubPageCoordinator: EPUB.PageCoordinator

    init(epub: EPUB) {
        self.epub = epub
        self.epubPageCoordinator = epub.newPageCoordinator()

        super.init(style: .plain)

        self.epubMetadataObservation = epub.$metadata
            .sink { [weak self](metadata) in
                self?.title = [metadata?.creator, metadata?.title].compactMap { $0 }.joined(separator: " - ")
            }

        self.epubPageCoordinatorSubscription = epubPageCoordinator.pagePositionsPublisher
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    debugPrint(error)
                }
            }, receiveValue: { _ in
                self.tableView.reloadData()
            })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem

        tableView.register(EPUBReaderScrollingTableViewCell.self, forCellReuseIdentifier: Self.cellReuseIdentifier)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        self.epubPageCoordinator.pageSize = .init(width: size.width, height: .greatestFiniteMagnitude)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.epubPageCoordinator.pageSize = .init(width: view.bounds.size.width, height: .greatestFiniteMagnitude)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ((try? epubPageCoordinator.pagePositions.get())?[indexPath.row])
            .flatMap { $0.itemRef }
            .flatMap { try? epubPageCoordinator.spineItemHeightForRef($0) } ?? 0
    }

    // MARK: - Table view data source

    /*
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }
    */

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (try? epubPageCoordinator.pagePositions.get().count) ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellReuseIdentifier, for: indexPath) as? EPUBReaderScrollingTableViewCell else {
            fatalError()
        }

        // Configure the cell...
        cell.pagePosition = (try? epubPageCoordinator.pagePositions.get())?[indexPath.row]

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
