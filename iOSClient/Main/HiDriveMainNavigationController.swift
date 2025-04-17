//
//  HiDriveMainNavigationController.swift
//  Nextcloud
//
//  Created by Sergey Kaliberda on 20.02.2025.
//  Copyright © 2025 STRATO GmbH. All rights reserved.
//

import UIKit

class HiDriveMainNavigationController: UINavigationController, UINavigationControllerDelegate {
    
    var accountButtonFactory: AccountButtonFactory!
    
    var controller: NCMainTabBarController? {
        self.tabBarController as? NCMainTabBarController
    }
    
    var collectionViewCommon: NCCollectionViewCommon? {
        topViewController as? NCCollectionViewCommon
    }
    
    var session: NCSession.Session {
        NCSession.shared.getSession(controller: controller)
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        setNavigationBarAppearance()
    }
    
    private var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        navigationBar.prefersLargeTitles = false
        setNavigationBarHidden(false, animated: true)
        
        accountButtonFactory = AccountButtonFactory(controller: controller,
                                                    onAccountDetailsOpen: { [weak self] in self?.collectionViewCommon?.setEditMode(false) },
                                                    presentVC: { [weak self] vc in self?.present(vc, animated: true) },
                                                    onMenuOpened: { [weak self] in self?.collectionViewCommon?.dismissTip() })
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            self.timer?.invalidate()
            self.timer = nil
        }

        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if UIApplication.shared.applicationState == .active {
                    self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
                        self.setNavigationRightItems()
                    })
                }
            }
        }
    }
    
    func setNavigationLeftItems() {
        guard let collectionViewCommon else {
            return
        }
        
        if collectionViewCommon.isSearchingMode && (UIDevice.current.userInterfaceIdiom == .phone) {
            collectionViewCommon.navigationItem.leftBarButtonItems = nil
            return
        }
        
        if isCurrentScreenInMainTabBar() {
            collectionViewCommon.navigationItem.leftItemsSupplementBackButton = true
            if viewControllers.count == 1 {
                let burgerMenuItem = UIBarButtonItem(image: UIImage(resource: .BurgerMenu.bars),
                                                     style: .plain,
                                                     action: { [weak self] in
                    self?.mainTabBarController?.showBurgerMenu()
                })
                burgerMenuItem.tintColor = UIColor(resource: .BurgerMenu.navigationBarButton)
                collectionViewCommon.navigationItem.setLeftBarButtonItems([burgerMenuItem], animated: true)
            }
        } else if (collectionViewCommon.layoutKey == NCGlobal.shared.layoutViewRecent) ||
                    (collectionViewCommon.layoutKey == NCGlobal.shared.layoutViewOffline) {
            collectionViewCommon.navigationItem.leftItemsSupplementBackButton = true
            if viewControllers.count == 1 {
                let closeButton = UIBarButtonItem(title: NSLocalizedString("_close_", comment: ""),
                                                  style: .plain,
                                                  action: { [weak self] in
                    self?.dismiss(animated: true)
                })
                closeButton.tintColor = NCBrandColor.shared.iconImageColor
                collectionViewCommon.navigationItem.setLeftBarButtonItems([closeButton], animated: true)
            }
        }
    }
    
    func setNavigationRightItems() {
        guard let collectionViewCommon else {
            return
        }
        
        if collectionViewCommon.isSearchingMode && (UIDevice.current.userInterfaceIdiom == .phone) {
            collectionViewCommon.navigationItem.rightBarButtonItems = nil
            return
        }
        
        guard collectionViewCommon.layoutKey != NCGlobal.shared.layoutViewTransfers else { return }
        
        if collectionViewCommon.isEditMode {
            collectionViewCommon.tabBarSelect?.update(fileSelect: collectionViewCommon.fileSelect,
                                                     metadatas: collectionViewCommon.getSelectedMetadatas(),
                                                     userId: session.userId)
            collectionViewCommon.tabBarSelect?.show()
        } else {
            collectionViewCommon.tabBarSelect?.hide()
            collectionViewCommon.navigationItem.rightBarButtonItems = isCurrentScreenInMainTabBar() ?
            [createAccountButton(), createTransfersButtonIfNeeded()].compactMap { $0 }
            : []
        }
    }
    
    private func createAccountButton() -> UIBarButtonItem {
        accountButtonFactory.createAccountButton()
    }
    
    private func createTransfersButtonIfNeeded() -> UIBarButtonItem? {
        let resultsCount = NCManageDatabase.shared.getResultsMetadatas(predicate: NSPredicate(format: "status != %i", NCGlobal.shared.metadataStatusNormal))?.count ?? 0
        guard resultsCount > 0 else { return nil }
        let transfersButton = UIBarButtonItem(image: UIImage(systemName: "arrow.left.arrow.right.circle.fill"),
                                              style: .plain) { [weak self] in
            if let navigationController = UIStoryboard(name: "NCTransfers", bundle: nil).instantiateInitialViewController() as? UINavigationController,
               let viewController = navigationController.topViewController as? NCTransfers {
                viewController.modalPresentationStyle = .pageSheet
                self?.present(navigationController, animated: true, completion: nil)
            }
        }
        return transfersButton
    }
}
