//
//  HiDriveMainNavigationController.swift
//  Nextcloud
//
//  Created by Sergey Kaliberda on 20.02.2025.
//  Copyright © 2025 STRATO GmbH. All rights reserved.
//

import UIKit
import SwiftUI
import NextcloudKit

class HiDriveMainNavigationController: UINavigationController, UINavigationControllerDelegate {

    var accountButtonFactory: AccountButtonFactory!

    private var areActiveTransfersPresent = false
    private let transfersDebouncer = NCDebouncer(delay: .seconds(1), maxEventCount: NCBrandOptions.shared.numMaximumProcess)

    var controller: NCMainTabBarController? {
        self.mainTabBarController
    }

    var collectionViewCommon: NCCollectionViewCommon? {
        topViewController as? NCCollectionViewCommon
    }

    var ncMedia: NCMedia? {
        topViewController as? NCMedia
    }

    var session: NCSession.Session {
        NCSession.shared.getSession(controller: controller)
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        setNavigationBarAppearance()
        setNavigationRightItems()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
        navigationBar.prefersLargeTitles = false
        setNavigationBarHidden(false, animated: true)

        accountButtonFactory = AccountButtonFactory(controller: controller,
                                                    onAccountDetailsOpen: { [weak self] in
            self?.collectionViewCommon?.setEditMode(false)
            self?.ncMedia?.setEditMode(false)
        },
                                                    presentVC: { [weak self] vc in self?.present(vc, animated: true) },
                                                    onMenuOpened: { [weak self] in self?.collectionViewCommon?.dismissTip() })

        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] _ in
            self?.unregisterTransferDelegate()
        }

        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            Task {
                await self?.registerAndRefreshTransfers(immediate: true)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task {
            await registerAndRefreshTransfers(immediate: true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterTransferDelegate()
    }

    private var isSelectedTabNavigationController: Bool {
        tabBarController?.selectedViewController === self
    }

    private func unregisterTransferDelegate() {
        Task {
            await NCNetworking.shared.transferDispatcher.removeDelegate(self)
        }
    }

    private func registerAndRefreshTransfers(immediate: Bool) async {
        guard !isAppInBackground, isSelectedTabNavigationController else { return }
        await NCNetworking.shared.transferDispatcher.addDelegate(self)
        await transfersDebouncer.call({ [weak self] in
            await self?.updateActiveTransfersPresence()
        }, immediate: immediate)
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
        if let collectionViewCommon {
            setNavigationRightItems(for: collectionViewCommon)
        } else if let ncMedia {
            setNavigationRightItems(for: ncMedia)
        }
    }

    private func setNavigationRightItems(for collectionViewCommon: NCCollectionViewCommon) {
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
            guard isCurrentScreenInMainTabBar() else {
                collectionViewCommon.navigationItem.rightBarButtonItems = []
                return
            }
            setAccountAndTransfersButtons(on: collectionViewCommon)
        }
    }

    private func setNavigationRightItems(for ncMedia: NCMedia) {
        setAccountAndTransfersButtons(on: ncMedia)
    }

    private func setAccountAndTransfersButtons(on viewController: UIViewController) {
        Task { @MainActor in
            guard isCurrentScreenInMainTabBar() else { return }
            let accountButton = await createAccountButton()
            viewController.navigationItem.rightBarButtonItems =
                [accountButton, createTransfersButtonIfNeeded()].compactMap { $0 }
        }
    }

    private func createAccountButton() async -> UIBarButtonItem {
        await accountButtonFactory.createAccountButton()
    }

    private func createTransfersButtonIfNeeded() -> UIBarButtonItem? {
        guard areActiveTransfersPresent else {
            return nil
        }
        let transfersButton = UIBarButtonItem(image: UIImage(systemName: "arrow.left.arrow.right.circle.fill"),
                                              style: .plain) { [weak self] in
            let rootView = TransfersView(session: self?.session, onClose: { [weak self] in
                self?.dismiss(animated: true)
            })
            let hosting = UIHostingController(rootView: rootView)
            hosting.modalPresentationStyle = .pageSheet

            self?.present(hosting, animated: true)
        }
		transfersButton.tintColor = UIColor(resource: .Transfers.buttonBackground)
        return transfersButton
    }

    func updateMenuOption() { }
}

// MARK: - NCTransferDelegate

extension HiDriveMainNavigationController: NCTransferDelegate {
    var sceneIdentifier: String {
        controller?.sceneIdentifier ?? ""
    }

    func transferReloadData(serverUrl: String?) { }

    func transferProgressDidUpdate(progress: Float, totalBytes: Int64, totalBytesExpected: Int64, fileName: String, serverUrl: String) { }

    func transferChange(status: String,
                        account: String,
                        fileName: String,
                        serverUrl: String,
                        selector: String?,
                        ocId: String,
                        destination: String?,
                        error: NKError) {
        Task {
            await scheduleTransfersRefresh()
        }
    }

    func transferReloadDataSource(serverUrl: String?, requestData: Bool, status: Int?) {
        Task {
            await scheduleTransfersRefresh()
        }
    }

    private func scheduleTransfersRefresh() async {
        guard !isAppInBackground else { return }
        await transfersDebouncer.call { [weak self] in
            await self?.updateActiveTransfersPresence()
        }
    }

    @MainActor
    private func updateActiveTransfersPresence() async {
        guard !isAppInBackground else { return }
        let activeTransfersPresent = await NCManageDatabase.shared.metadataExistsAsync(
            predicate: NSPredicate(format: "status != %i", NCGlobal.shared.metadataStatusNormal)
        )
        guard activeTransfersPresent != areActiveTransfersPresent else { return }
        areActiveTransfersPresent = activeTransfersPresent
        setNavigationRightItems()
    }
}
