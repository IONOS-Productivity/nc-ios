// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2026 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import UIKit
import NextcloudKit

class NCContextMenuPlus: NSObject {
    weak var menuButton: UIButton?
    weak var controller: NCMainTabBarController?

    init(menuButton: UIButton? = nil, controller: NCMainTabBarController?) {
        self.menuButton = menuButton
        self.controller = controller
    }

    @MainActor
    func create(session: NCSession.Session) async {
        guard let controller else {
            return
        }
        let capabilities = await NCManageDatabase.shared.getCapabilities(account: session.account) ?? NKCapabilities.Capabilities()
        let utility = NCUtility()
        let serverUrl = controller.currentServerUrl()

        let isDirectoryE2EE = await NCUtilityFileSystem().isDirectoryE2EEAsync(serverUrl: serverUrl, urlBase: session.urlBase, userId: session.userId, account: session.account)
        let isNetworkReachable = NextcloudKit.shared.isNetworkReachable()
        let titleCreateFolder = NSLocalizedString("_create_folder_", comment: "")
        let imageCreateFolder = NCImageCache.shared.getFolder(account: session.account)

        var menuActionElement: [UIMenuElement] = []

        // ------------------------------- ACTION

        menuActionElement.append(UIAction(title: NSLocalizedString("_upload_photos_videos_", comment: ""),
                                          image: UIImage(resource: .photoOrVideo)) { _ in
            NCAskAuthorization().askAuthorizationPhotoLibrary(controller: controller) { hasPermission in
                if hasPermission {
                    DispatchQueue.main.async {
                        NCPhotosPickerViewController(controller: controller, maxSelectedAssets: 0, singleSelectedMode: false)
                    }
                }
            }
        })

        menuActionElement.append(UIAction(title: NSLocalizedString("_upload_file_", comment: ""),
                                          image: UIImage(resource: .uploadFile)) { _ in
            DispatchQueue.main.async {
                controller.documentPickerViewController = NCDocumentPickerViewController(controller: controller, isViewerMedia: false, allowsMultipleSelection: true)
            }
        })

        menuActionElement.append(UIAction(title: NSLocalizedString("_scans_document_", comment: ""),
                                          image: UIImage(resource: .scan)) { _ in
            DispatchQueue.main.async {
                NCDocumentCamera.shared.openScannerDocument(viewController: controller)
            }
        })

        menuActionElement.append(UIAction(title: titleCreateFolder,
                                          image: imageCreateFolder) { _ in
            DispatchQueue.main.async {
                let alertController = UIAlertController.createFolderWith(
                    serverUrl: serverUrl,
                    session: session,
                    sceneIdentifier: controller.sceneIdentifier,
                    capabilities: capabilities) { error in
                        if error != .success {
                            Task {
                                await showErrorBanner(controller: controller,
                                                      text: error.errorDescription,
                                                      errorCode: error.errorCode)
                            }
                        }
                    }
                controller.present(alertController, animated: true, completion: nil)
            }
        })

        let menuAction = UIMenu(title: "", options: .displayInline, children: menuActionElement)

        let plusMenu = UIMenu(children: [menuAction])

        if let menuButton {
            if #available(iOS 14.0, *) {
                menuButton.menu = plusMenu
                menuButton.showsMenuAsPrimaryAction = true
                menuButton.performPrimaryAction()
            }
            // E2EE Offile disable
            if !isNetworkReachable, isDirectoryE2EE {
                menuButton.isEnabled = false
            } else {
                menuButton.isEnabled = true
            }
        }
    }

    @MainActor
    func hiddenPlusButton(_ isHidden: Bool, animation: Bool = true) {
        guard let menuButton else {
            return
        }
        let tx = 200.0
        if isHidden {
            if menuButton.transform.tx == tx {
                menuButton.alpha = 0
                return
            }
            if animation {
                UIView.animate(withDuration: 0.5, delay: 0.0, options: [], animations: {
                    menuButton.transform = CGAffineTransform(translationX: tx, y: 0)
                    menuButton.alpha = 0
                })
            } else {
                menuButton.transform = CGAffineTransform(translationX: tx, y: 0)
                menuButton.alpha = 0
            }
        } else {
            if menuButton.transform.tx == 0.0 {
                menuButton.alpha = 1
                return
            }
            if animation {
                UIView.animate(withDuration: 0.5, delay: 0.3, options: [], animations: {
                    menuButton.transform = .identity
                    menuButton.alpha = 1
                })
            } else {
                menuButton.transform = .identity
                menuButton.alpha = 1
            }
        }
    }

    @MainActor
    func resetPlusButtonAlpha(animated: Bool = true) {
        guard let menuButton else {
            return
        }
        let update = {
            menuButton.alpha = 1.0
        }
        if animated {
            UIView.animate(withDuration: 0.3, animations: update)
        } else {
            update()
        }
    }
}
