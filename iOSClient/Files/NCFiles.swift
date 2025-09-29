//
//  NCFiles.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 26/09/2020.
//  Copyright © 2020 Marino Faggiana. All rights reserved.
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
import NextcloudKit
import RealmSwift
import SwiftUI

class NCFiles: NCCollectionViewCommon {

    internal var fileNameBlink: String?
    internal var fileNameOpen: String?

    internal var lastOffsetY: CGFloat = 0
    internal var lastScrollTime: TimeInterval = 0
    internal var accumulatedScrollDown: CGFloat = 0

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        titleCurrentFolder = NCBrandOptions.shared.brand
        layoutKey = NCGlobal.shared.layoutViewFiles
        headerRichWorkspaceDisable = false
        emptyTitle = "_files_no_files_"
        emptyDescription = "_no_file_pull_down_"
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        enableSearchBar = !isOpenedFromSearchResults()
        
        super.viewDidLoad()

        if self.serverUrl.isEmpty {

            ///
            /// Set ServerURL when start (isEmpty)
            ///
            self.serverUrl = utilityFileSystem.getHomeServer(session: session)
            self.titleCurrentFolder = getNavigationTitle()

            NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: NCGlobal.shared.notificationCenterChangeUser), object: nil, queue: nil) { notification in
                if let userInfo = notification.userInfo, let account = userInfo["account"] as? String {
                    if let controller = userInfo["controller"] as? NCMainTabBarController,
                       controller == self.controller {
                        controller.account = account
                    } else {
                        return
                    }
                }

                self.navigationController?.popToRootViewController(animated: false)
                self.serverUrl = self.utilityFileSystem.getHomeServer(session: self.session)
                self.isSearchingMode = false
                self.isEditMode = false
                self.fileSelect.removeAll()
                self.layoutForView = self.database.getLayoutForView(account: self.session.account, key: self.layoutKey, serverUrl: self.serverUrl)

                if self.isLayoutList {
                    self.collectionView?.collectionViewLayout = self.listLayout
                } else if self.isLayoutGrid {
                    self.collectionView?.collectionViewLayout = self.gridLayout
                } else if self.isLayoutPhoto {
                    self.collectionView?.collectionViewLayout = self.mediaLayout
                }

                self.titleCurrentFolder = self.getNavigationTitle()
                self.navigationItem.title = self.titleCurrentFolder
                (self.navigationController as? HiDriveMainNavigationController)?.setNavigationLeftItems()

                self.reloadDataSource()
                self.getServerData()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reloadDataSource()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !self.dataSource.isEmpty() {
            self.blinkCell(fileName: self.fileNameBlink)
            self.openFile(fileName: self.fileNameOpen)
            self.fileNameBlink = nil
            self.fileNameOpen = nil
        }

        if !isSearchingMode {
            getServerData()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        fileNameBlink = nil
        fileNameOpen = nil
    }


    // MARK: - DataSource

    override func reloadDataSource() {
        guard !isSearchingMode
        else {
            return super.reloadDataSource()
        }

        var predicate = self.defaultPredicate
        let predicateDirectory = NSPredicate(format: "account == %@ AND serverUrl == %@", self.session.account, self.serverUrl)

        if NCKeychain().getPersonalFilesOnly(account: self.session.account) {
            predicate = self.personalFilesOnlyPredicate
        }

        self.metadataFolder = self.database.getMetadataFolder(session: self.session, serverUrl: self.serverUrl)
        self.richWorkspaceText = self.database.getTableDirectory(predicate: predicateDirectory)?.richWorkspace

        self.database.getMetadatas(predicate: predicate,
                                   layoutForView: self.layoutForView,
                                   account: self.session.account) { metadatas, layoutForView, account in
            self.dataSource = NCCollectionViewDataSource(metadatas: metadatas, layoutForView: layoutForView, account: account)
            self.dataSource.caching(metadatas: metadatas) {
                super.reloadDataSource()
            }
        }
    }

    override func getServerData() {
        guard !isSearchingMode else {
            return networkSearch()
        }

        func downloadMetadata(_ metadata: tableMetadata) -> Bool {
            let fileSize = utilityFileSystem.fileProviderStorageSize(metadata.ocId, fileNameView: metadata.fileNameView)
            guard fileSize > 0 else { return false }

            if let localFile = database.getResultsTableLocalFile(predicate: NSPredicate(format: "ocId == %@", metadata.ocId))?.first {
                if localFile.etag != metadata.etag {
                    return true
                }
            }
            return false
        }

        DispatchQueue.global().async {
            self.networkReadFolder { metadatas, error in
                if error == .success {
                    let metadatas: [tableMetadata] = metadatas ?? self.dataSource.getMetadatas()
                    for metadata in metadatas where !metadata.directory && downloadMetadata(metadata) {
                        if let metadata = self.database.setMetadataSessionInWaitDownload(ocId: metadata.ocId,
                                                                                         session: NCNetworking.shared.sessionDownload,
                                                                                         selector: NCGlobal.shared.selectorDownloadFile,
                                                                                         sceneIdentifier: self.controller?.sceneIdentifier) {
                            NCNetworking.shared.download(metadata: metadata)
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.refreshControlEndRefreshing()
                    self.reloadDataSource()
                }
            }
        }
    }

    private func networkReadFolder(completion: @escaping (_ metadatas: [tableMetadata]?, _ error: NKError) -> Void) {
        NCNetworking.shared.readFile(serverUrlFileName: serverUrl, account: session.account) { task in
            self.dataSourceTask = task
            if self.dataSource.isEmpty() {
                self.collectionView.reloadData()
            }
        } completion: { account, metadata, error in
            let isDirectoryE2EE = NCUtilityFileSystem().isDirectoryE2EE(session: self.session, serverUrl: self.serverUrl)
            guard error == .success, let metadata else {
                return completion(nil, error)
            }
            /// Check change eTag or E2EE  or DataSource empty
            self.database.updateDirectoryRichWorkspace(metadata.richWorkspace, account: account, serverUrl: self.serverUrl)
            let tableDirectory = self.database.getTableDirectory(ocId: metadata.ocId)
            guard tableDirectory?.etag != metadata.etag || metadata.e2eEncrypted || self.dataSource.isEmpty() else {
                return completion(nil, NKError())
            }

            NCNetworking.shared.readFolder(serverUrl: self.serverUrl,
                                           account: metadata.account,
                                           queue: NextcloudKit.shared.nkCommonInstance.backgroundQueue) { task in
                self.dataSourceTask = task
                if self.dataSource.isEmpty() {
                    self.collectionView.reloadData()
                }
            } completion: { account, metadataFolder, metadatas, error in
                Task {
                    /// Error
                    guard error == .success else {
                        return completion(nil, error)
                    }
                    /// Updata folder
                    if let metadataFolder {
                        self.metadataFolder = metadataFolder.detachedCopy()
                        self.richWorkspaceText = metadataFolder.richWorkspace
                    }

                    guard let metadataFolder,
                          isDirectoryE2EE,
                          NCKeychain().isEndToEndEnabled(account: account),
                          await !NCNetworkingE2EE().isInUpload(account: account, serverUrl: self.serverUrl) else {
                        return completion(metadatas, error)
                    }

                    /// E2EE
                    let lock = await self.database.getE2ETokenLockAsync(account: account, serverUrl: self.serverUrl)
                    let results = await NCNetworkingE2EE().getMetadata(fileId: metadataFolder.ocId, e2eToken: lock?.e2eToken, account: account)

                    if results.error == .success,
                       let e2eMetadata = results.e2eMetadata,
                       let signature = results.signature,
                       let version = results.version {
                        let error = await NCEndToEndMetadata().decodeMetadata(e2eMetadata, signature: signature, serverUrl: self.serverUrl, session: self.session)
                        let capabilities = NKCapabilities.shared.getCapabilitiesBlocking(for: self.session.account)
                        if error == .success {
                            if version == "v1", capabilities.e2EEApiVersion == NCGlobal.shared.e2eeVersionV20 {
                                nkLog(tag: self.global.logTagE2EE, message: "Conversion v1 to v2")
                                NCActivityIndicator.shared.start()
                                let serverUrl = metadataFolder.serverUrl + "/" + metadataFolder.fileName
                                let error = await NCNetworkingE2EE().uploadMetadata(serverUrl: serverUrl, updateVersionV1V2: true, account: account)
                                if error != .success {
                                    NCContentPresenter().showError(error: error)
                                }
                                NCActivityIndicator.shared.stop()
                            }
                        } else {
                            // Client Diagnostic
                            await self.database.addDiagnosticAsync(account: account, issue: NCGlobal.shared.diagnosticIssueE2eeErrors)
                            NCContentPresenter().showError(error: error)
                        }
                    } else if results.error.errorCode == NCGlobal.shared.errorResourceNotFound {
                        // no metadata found, send a new metadata
                        let serverUrl = metadataFolder.serverUrl + "/" + metadataFolder.fileName
                        let error = await NCNetworkingE2EE().uploadMetadata(serverUrl: serverUrl, account: account)
                        if error != .success {
                            NCContentPresenter().showError(error: error)
                        }
                    } else {
                        NCContentPresenter().showError(error: NKError(errorCode: NCGlobal.shared.errorE2EEKeyDecodeMetadata, errorDescription: "_e2e_error_"))
                    }
                    completion(metadatas, error)
                }
            }
        }
    }

    func blinkCell(fileName: String?) {
        if let fileName = fileName, let metadata = database.getMetadata(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileName == %@", session.account, self.serverUrl, fileName)) {
            let indexPath = self.dataSource.getIndexPathMetadata(ocId: metadata.ocId)
            if let indexPath = indexPath {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UIView.animate(withDuration: 0.3) {
                        self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
                    } completion: { _ in
                        if let cell = self.collectionView.cellForItem(at: indexPath) {
                            cell.backgroundColor = .darkGray
                            UIView.animate(withDuration: 2) {
                                cell.backgroundColor = .clear
                            }
                        }
                    }
                }
            }
        }
    }

    func openFile(fileName: String?) {
        if let fileName = fileName, let metadata = database.getMetadata(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileName == %@", session.account, self.serverUrl, fileName)) {
            let indexPath = self.dataSource.getIndexPathMetadata(ocId: metadata.ocId)
            if let indexPath = indexPath {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.collectionView(self.collectionView, didSelectItemAt: indexPath)
                }
            }
        }
    }
    
    private func isOpenedFromSearchResults() -> Bool {
        return self.navigationController?.viewControllers.contains(where: { viewController in
            return (viewController as? NCCollectionViewCommon)?.isSearchingMode ?? false
        }) ?? false
    }

    // MARK: - NCAccountSettingsModelDelegate

    override func accountSettingsDidDismiss(tableAccount: tableAccount?, controller: NCMainTabBarController?) {
        let currentAccount = session.account

        if database.getAllTableAccount().isEmpty {
            let navigationController: UINavigationController?

            if NCBrandOptions.shared.disable_intro, let viewController = UIStoryboard(name: "NCLogin", bundle: nil).instantiateViewController(withIdentifier: "NCLogin") as? NCLogin {
                navigationController = UINavigationController(rootViewController: viewController)
            } else {
                navigationController = UIStoryboard(name: "NCIntro", bundle: nil).instantiateInitialViewController() as? UINavigationController
            }

            UIApplication.shared.firstWindow?.rootViewController = navigationController
        } else if let account = tableAccount?.account, account != currentAccount {
            NCAccount().changeAccount(account, userProfile: nil, controller: controller) { }
        } else if self.serverUrl == self.utilityFileSystem.getHomeServer(session: self.session) {
            self.titleCurrentFolder = getNavigationTitle()
            navigationItem.title = self.titleCurrentFolder
        }

        (self.navigationController as? HiDriveMainNavigationController)?.setNavigationLeftItems()
    }
}
