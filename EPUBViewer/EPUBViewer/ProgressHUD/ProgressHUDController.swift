//
//  ProgressHUDController.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/13.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import UIKit
import JGProgressHUD

class ProgressHUDController: UIViewController {
    init(style: Style) {
        self.progressHUD = JGProgressHUD(style: style.jgProgressHUDStyle)

        super.init(nibName: nil, bundle: nil)

        self.modalTransitionStyle = .crossDissolve
        self.modalPresentationStyle = .overCurrentContext
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var progressHUD: JGProgressHUD

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        progressHUD.show(in: self.view, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        progressHUD.dismiss(animated: animated)
    }
}

extension ProgressHUDController {
    enum Style {
        case extraLight
        case light
        case dark
    }
}

extension ProgressHUDController.Style {
    var jgProgressHUDStyle: JGProgressHUDStyle {
        switch self {
        case .extraLight:
            return .extraLight
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
