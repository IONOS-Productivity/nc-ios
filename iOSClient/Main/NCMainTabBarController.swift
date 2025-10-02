//
//  NCMainTabBarController.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 02/04/24.
//  Copyright © 2024 Marino Faggiana. All rights reserved.
//  Copyright © 2024 STRATO GmbH
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import UIKit
import SwiftUI
import NextcloudKit

struct NavigationCollectionViewCommon {
    var serverUrl: String
    var navigationController: UINavigationController?
    var viewController: NCCollectionViewCommon
}

class NCMainTabBarController: UITabBarController {
    var sceneIdentifier: String = UUID().uuidString
    var account: String = "" {
        didSet {
            NCImageCache.shared.controller = self
        }
    }
    var availableNotifications: Bool = false
    var documentPickerViewController: NCDocumentPickerViewController?
    let navigationCollectionViewCommon = ThreadSafeArray<NavigationCollectionViewCommon>()
    private var previousIndex: Int?
    private var checkUserDelaultErrorInProgress: Bool = false
    private var timer: Timer?
    private let global = NCGlobal.shared

    private(set) var burgerMenuController: BurgerMenuAttachController?

    var window: UIWindow? {
        return SceneManager.shared.getWindow(controller: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
		if #available(iOS 17.0, *) {
			traitOverrides.horizontalSizeClass = .compact
		}

        NCDownloadAction.shared.setup(sceneIdentifier: sceneIdentifier)

        tabBar.tintColor = NCBrandColor.shared.getElement(account: account)

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: self.global.notificationCenterChangeTheming), object: nil, queue: .main) { [weak self] notification in
            if let userInfo = notification.userInfo as? NSDictionary,
               let account = userInfo["account"] as? String,
               self?.account == account {
                self?.tabBar.tintColor = NCBrandColor.shared.getElement(account: account)
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: self.global.notificationCenterCheckUserDelaultErrorDone), object: nil, queue: nil) { notification in
            if let userInfo = notification.userInfo,
               let account = userInfo["account"] as? String,
               let controller = userInfo["controller"] as? NCMainTabBarController,
               account == self.account,
               controller == self {
                self.checkUserDelaultErrorInProgress = false
            }
        }

        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            self.timer?.invalidate()
            self.timer = nil
        }

		setupTabBarView()
        burgerMenuController = BurgerMenuAttachController(with: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DataProtectionAgreementManager.shared.showAgreement(viewController: self)

        previousIndex = selectedIndex
        if NCBrandOptions.shared.enforce_passcode_lock && NCKeychain().passcode.isEmptyOrNil {
            let vc = UIHostingController(rootView: SetupPasscodeView(isLockActive: .constant(false)))
            vc.isModalInPresentation = true

            present(vc, animated: true)
        }
    }

	private func setupTabBarView() {
		if UIDevice.current.userInterfaceIdiom == .pad {
			tabBar.itemPositioning = .centered
			if let itemsCount = tabBar.items?.count {
				tabBar.itemWidth = UITabBarGuideline.padItemWidth
				tabBar.itemSpacing = UITabBarGuideline.padItemsSpacing(for: view.bounds.width, itemsCount: itemsCount)
			}
		}
	}

    func showBurgerMenu() {
        burgerMenuController?.showMenu()
    }

    func presentedNavigationController() -> UINavigationController? {
        return presentedViewController as? UINavigationController
    }

    func currentViewController() -> UIViewController? {
        if let navVC = presentedNavigationController() {
            return navVC.topViewController
        }
        return (selectedViewController as? UINavigationController)?.topViewController
    }

    func currentServerUrl() -> String {
        let session = NCSession.shared.getSession(account: account)
        var serverUrl = NCUtilityFileSystem().getHomeServer(session: session)
        let viewController = currentViewController()
        if let collectionViewCommon = viewController as? NCCollectionViewCommon {
            if !collectionViewCommon.serverUrl.isEmpty {
                serverUrl = collectionViewCommon.serverUrl
            }
        }
        return serverUrl
    }

    func hide() {
        if #available(iOS 18.0, *) {
            setTabBarHidden(true, animated: true)
        } else {
            tabBar.isHidden = true
        }
    }

    func show() {
        if #available(iOS 18.0, *) {
            setTabBarHidden(false, animated: true)
        } else {
            tabBar.isHidden = false
        }
    }
}

extension NCMainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if previousIndex == tabBarController.selectedIndex {
            scrollToTop(viewController: viewController)
        }
        previousIndex = tabBarController.selectedIndex
    }

    private func scrollToTop(viewController: UIViewController) {
        guard let navigationController = viewController as? UINavigationController,
              let topViewController = navigationController.topViewController else { return }

        if let scrollView = topViewController.view.subviews.compactMap({ $0 as? UIScrollView }).first {
            scrollView.setContentOffset(CGPoint(x: 0, y: -scrollView.adjustedContentInset.top), animated: true)
        }
    }
}
