// SPDX-FileCopyrightText: STRATO GmbH
// SPDX-FileCopyrightText: 2026 Serhii Kaliberda
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import NextcloudKit

extension UIViewController {

    func presentMenu(with actions: [NCMenuAction], menuColor: UIColor = UIColor(resource: .FileMenu.background), textColor: UIColor = NCBrandColor.shared.textColor, controller: NCMainTabBarController? = nil, sender: Any?) {
        guard !actions.isEmpty else { return }
        let actions = actions.sorted(by: { $0.order < $1.order })
        guard let menuViewController = NCMenu.makeNCMenu(with: actions, menuColor: menuColor, textColor: textColor, controller: controller) else {
            let error = NKError(errorCode: NCGlobal.shared.errorInternalError, errorDescription: "_internal_generic_error_")
            NCContentPresenter().showError(error: error)
            return
        }

        let menuPanelController = NCMenuPanelController()
        menuPanelController.parentPresenter = self
        menuPanelController.delegate = menuViewController
        menuPanelController.set(contentViewController: menuViewController)
        menuPanelController.track(scrollView: menuViewController.tableView)

        present(menuPanelController, animated: true, completion: nil)
    }
}
