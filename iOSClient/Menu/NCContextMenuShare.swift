// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2026 Milen Pivchev
// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import UIKit
import NextcloudKit

/// A context menu for share actions (details, unshare, permissions).
/// See ``NCShare`` for usage details.
class NCContextMenuShare: NSObject {
    let share: tableShare
    let isDirectory: Bool
    let canReshare: Bool
    let utility = NCUtility()
    let database = NCManageDatabase.shared
    let shareController: NCShare

    init(share: tableShare, isDirectory: Bool, canReshare: Bool, shareController: NCShare) {
        self.share = share
        self.isDirectory = isDirectory
        self.canReshare = canReshare
        self.shareController = shareController
    }

    func viewMenu() -> UIMenu {
        var actions: [UIMenuElement] = []

        // Add share link (only for public links with reshare permission)
        if share.shareType == NKShare.ShareType.publicLink.rawValue, canReshare {
            let addLinkAction = UIAction(
                title: NSLocalizedString("_share_add_sharelink_", comment: ""),
                image: UIImage(resource: .menuAdd)
            ) { [self] _ in
                shareController.makeNewLinkShare()
            }
            actions.append(addLinkAction)
        }

        // Details action
        let detailsAction = UIAction(
            title: NSLocalizedString("_details_", comment: ""),
            image: UIImage(resource: .details)
        ) { [self] _ in
            openAdvancePermission(shareController: shareController)
        }
        actions.append(detailsAction)

        // Unshare action (destructive)
        let unshareAction = UIAction(
            title: NSLocalizedString("_share_unshare_", comment: ""),
            image: UIImage(resource: .unshare),
            attributes: .destructive
        ) { [self] _ in
            Task {
                await performUnshare(shareController: shareController)
            }
        }
        actions.append(unshareAction)

        return UIMenu(title: "", children: actions)
    }

    private func openAdvancePermission(shareController: NCShare) {
        guard let advancePermission = UIStoryboard(name: "NCShare", bundle: nil).instantiateViewController(withIdentifier: "NCShareAdvancePermission") as? NCShareAdvancePermission,
              let navigationController = shareController.navigationController,
              !share.isInvalidated,
              let metadata = shareController.metadata else { return }

        advancePermission.networking = shareController.networking
        advancePermission.share = tableShare(value: share)
        advancePermission.oldTableShare = tableShare(value: share)
        advancePermission.metadata = metadata

        if let downloadLimit = try? database.getDownloadLimit(byAccount: metadata.account, shareToken: share.token) {
            advancePermission.downloadLimit = .limited(limit: downloadLimit.limit, count: downloadLimit.count)
        }

        navigationController.pushViewController(advancePermission, animated: true)
    }

    @MainActor
    private func performUnshare(shareController: NCShare) async {
        let capabilities = NCNetworking.shared.capabilities[share.account] ?? NKCapabilities.Capabilities()

        if share.shareType != NKShare.ShareType.publicLink.rawValue,
           let metadata = shareController.metadata,
           metadata.e2eEncrypted && NCGlobal.shared.isE2eeVersion2(capabilities.e2EEApiVersion) {
            if await NCNetworkingE2EE().isInUpload(account: metadata.account, serverUrl: metadata.serverUrlFileName) {
                let error = NKError(errorCode: NCGlobal.shared.errorE2EEUploadInProgress, errorDescription: NSLocalizedString("_e2e_in_upload_", comment: ""))
                return NCContentPresenter().showInfo(error: error)
            }
            let error = await NCNetworkingE2EE().uploadMetadata(serverUrl: metadata.serverUrlFileName, addUserId: nil, removeUserId: share.shareWith, account: metadata.account)
            if error != .success {
                return NCContentPresenter().showError(error: error)
            }
        }
        shareController.networking?.unShare(idShare: share.idShare)
    }
}
