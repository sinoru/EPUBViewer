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

    lazy var dataSource = UITableViewDiffableDataSource<Section, EPUB.PagePosition>(tableView: tableView) { (tableView, indexPath, pagePosition) -> UITableViewCell? in
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellReuseIdentifier, for: indexPath) as? EPUBReaderScrollingTableViewCell else {
            fatalError()
        }

        // Configure the cell...
        self.addChild(cell.webViewController)
        cell.pagePosition = pagePosition

        return cell
    }

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
            }, receiveValue: { (pagePositions) in
                var snapshot = self.dataSource.snapshot()

                Section.allCases.difference(from: snapshot.sectionIdentifiers).forEach {
                    switch $0 {
                    case .insert(let offset, let element, _):
                        if offset == snapshot.sectionIdentifiers.count {
                            snapshot.appendSections([element])
                        } else {
                            snapshot.insertSections([element], beforeSection: snapshot.sectionIdentifiers[offset])
                        }
                    case .remove(_, let element, _):
                        snapshot.deleteSections([element])
                    }
                }

                pagePositions.difference(from: snapshot.itemIdentifiers).forEach {
                    switch $0 {
                    case .insert(let offset, let element, _):
                        if offset == snapshot.itemIdentifiers.count {
                            snapshot.appendItems([element])
                        } else {
                            snapshot.insertItems([element], beforeItem: snapshot.itemIdentifiers[offset])
                        }
                    case .remove(_, let element, _):
                        snapshot.deleteItems([element])
                    }
                }

                self.dataSource.apply(snapshot)
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
        tableView.dataSource = dataSource
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
        return dataSource.itemIdentifier(for: indexPath)?.pageSize.height ?? 0
    }
}
