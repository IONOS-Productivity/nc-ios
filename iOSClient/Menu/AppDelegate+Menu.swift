//
//  AppDelegate+Menu.swift
//  Nextcloud
//
//  Created by Philippe Weidmann on 24.01.20.
//  Copyright © 2020 Philippe Weidmann. All rights reserved.
//  Copyright © 2020 Marino Faggiana All rights reserved.
//  Copyright © 2024 STRATO GmbH
//
//  Author Philippe Weidmann <philippe.weidmann@infomaniak.com>
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
import FloatingPanel
import NextcloudKit

extension AppDelegate {
    func toggleMenu(controller: NCMainTabBarController, sender: Any?) {
        var actions: [NCMenuAction] = []
        let session = NCSession.shared.getSession(controller: controller)
        let utilityFileSystem = NCUtilityFileSystem()
        let serverUrl = controller.currentServerUrl()
        let isDirectoryE2EE = NCUtilityFileSystem().isDirectoryE2EE(serverUrl: serverUrl, urlBase: session.urlBase, userId: session.userId, account: session.account)
        let directory = NCManageDatabase.shared.getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", session.account, serverUrl))
        let utility = NCUtility()
        let canCreateOfficeFiles = false
        let capabilities = NCNetworking.shared.capabilities[session.account] ?? NKCapabilities.Capabilities()

        actions.append(
            NCMenuAction(
				title: NSLocalizedString("_upload_photos_videos_", comment: ""), icon: NCImagesRepository.menuIconUploadPhotosVideos, sender: sender, action: { _ in
					NCAskAuthorization().askAuthorizationPhotoLibrary(controller: controller) { hasPermission in
						if hasPermission {NCPhotosPickerViewController(controller: controller, maxSelectedAssets: 0, singleSelectedMode: false)
						}
					}
				}
            )
        )

        actions.append(
            NCMenuAction(
				title: NSLocalizedString("_upload_file_", comment: ""), icon: NCImagesRepository.menuIconUploadFile, sender: sender, action: { _ in
					controller.documentPickerViewController = NCDocumentPickerViewController(controller: controller, isViewerMedia: false, allowsMultipleSelection: true)
				}
            )
        )

        actions.append(
            NCMenuAction(
				title: NSLocalizedString("_scans_document_", comment: ""), icon: NCImagesRepository.menuIconScan, sender: sender, action: { _ in
					NCDocumentCamera.shared.openScannerDocument(viewController: controller)
				}
            )
        )

        if NCPreferences().isEndToEndEnabled(account: session.account) {
            actions.append(.seperator(order: 0, sender: sender))
        }

        let titleCreateFolder = isDirectoryE2EE ? NSLocalizedString("_create_folder_e2ee_", comment: "") : NSLocalizedString("_create_folder_", comment: "")
        let imageCreateFolder = NCImagesRepository.menuIconCreateFolder
        actions.append(
            NCMenuAction(title: titleCreateFolder,
                         icon: imageCreateFolder,
                         sender: sender,
                         action: { _ in
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
        )

        // Folder encrypted
        if serverUrl == utilityFileSystem.getHomeServer(session: session) && NCPreferences().isEndToEndEnabled(account: session.account) {
            actions.append(
                NCMenuAction(title: NSLocalizedString("_create_folder_e2ee_", comment: ""),
                             icon: NCImagesRepository.menuIconCreateFolder,
							 sender: sender, action: { _ in
                                 DispatchQueue.main.async {
                                     let alertController = UIAlertController.createFolderWith(
                                         serverUrl: serverUrl,
                                         session: session,
                                         markE2ee: true,
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
            )
        }

        if NCPreferences().isEndToEndEnabled(account: session.account) {
            actions.append(.seperator(order: 0, sender: sender))
        }

		guard canCreateOfficeFiles else {
			controller.presentMenu(with: actions, controller: controller, sender: sender)
			return
		}

        if NextcloudKit.shared.isNetworkReachable(),
           let creator = capabilities.directEditingCreators.first(where: { $0.editor == "onlyoffice" && $0.identifier == "onlyoffice_docx"}) {

            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_create_new_document_", comment: ""),
                    icon: utility.loadImage(named: "doc.text", colors: [NCBrandColor.shared.documentIconColor]),
                    sender: sender,
                    action: { _ in
                        Task { @MainActor in
                            let createDocument = NCCreate()
                            let templates = await createDocument.getTemplate(editorId: "onlyoffice", templateId: "document", account: session.account)
                            let fileName = await NCNetworking.shared.createFileName(fileNameBase: NSLocalizedString("_untitled_", comment: "") + "." + templates.ext, account: session.account, serverUrl: serverUrl)
                            let fileNamePath = utilityFileSystem.getRelativeFilePath(String(describing: fileName), serverUrl: serverUrl, session: session)

                            await createDocument.createDocument(controller: controller, fileNamePath: fileNamePath, fileName: String(describing: fileName), editorId: "onlyoffice", creatorId: creator.identifier, templateId: templates.selectedTemplate.identifier, account: session.account)
                        }
                    }
                )
            )
        }

        if NextcloudKit.shared.isNetworkReachable(),
           let creator = capabilities.directEditingCreators.first(where: { $0.editor == "onlyoffice" && $0.identifier == "onlyoffice_xlsx"}) {

            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_create_new_spreadsheet_", comment: ""),
                    icon: utility.loadImage(named: "tablecells", colors: [NCBrandColor.shared.spreadsheetIconColor]),
                    sender: sender,
                    action: { _ in
                        Task { @MainActor in
                            let createDocument = NCCreate()
                            let templates = await createDocument.getTemplate(editorId: "onlyoffice", templateId: "spreadsheet", account: session.account)
                            let fileName = await NCNetworking.shared.createFileName(fileNameBase: NSLocalizedString("_untitled_", comment: "") + "." + templates.ext, account: session.account, serverUrl: serverUrl)
                            let fileNamePath = utilityFileSystem.getRelativeFilePath(String(describing: fileName), serverUrl: serverUrl, session: session)

                            await createDocument.createDocument(controller: controller, fileNamePath: fileNamePath, fileName: String(describing: fileName), editorId: "onlyoffice", creatorId: creator.identifier, templateId: templates.selectedTemplate.identifier, account: session.account)
                        }
                    }
                )
            )
        }

        if NextcloudKit.shared.isNetworkReachable(),
           let creator = capabilities.directEditingCreators.first(where: { $0.editor == "onlyoffice" && $0.identifier == "onlyoffice_pptx"}) {

            actions.append(
                NCMenuAction(
                    title: NSLocalizedString("_create_new_presentation_", comment: ""),
                    icon: utility.loadImage(named: "play.rectangle", colors: [NCBrandColor.shared.presentationIconColor]),
                    sender: sender,
                    action: { _ in
                        Task { @MainActor in
                            let createDocument = NCCreate()
                            let templates = await createDocument.getTemplate(editorId: "onlyoffice", templateId: "presentation", account: session.account)
                            let fileName = await NCNetworking.shared.createFileName(fileNameBase: NSLocalizedString("_untitled_", comment: "") + "." + templates.ext, account: session.account, serverUrl: serverUrl)
                            let fileNamePath = utilityFileSystem.getRelativeFilePath(String(describing: fileName), serverUrl: serverUrl, session: session)

                            await createDocument.createDocument(controller: controller, fileNamePath: fileNamePath, fileName: String(describing: fileName), editorId: "onlyoffice", creatorId: creator.identifier, templateId: templates.selectedTemplate.identifier, account: session.account)
                        }
                    }
                )
            )
        }

        if capabilities.richDocumentsEnabled {
            if NextcloudKit.shared.isNetworkReachable() && !isDirectoryE2EE {
                actions.append(
                    NCMenuAction(
                        title: NSLocalizedString("_create_new_document_", comment: ""),
                        icon: utility.loadImage(named: "doc.richtext", colors: [NCBrandColor.shared.documentIconColor]),
                        sender: sender,
                        action: { _ in
                            Task { @MainActor in
                                let createDocument = NCCreate()
                                let templates = await createDocument.getTemplate(editorId: "collabora", templateId: "document", account: session.account)
                                let fileName = await NCNetworking.shared.createFileName(fileNameBase: NSLocalizedString("_untitled_", comment: "") + "." + templates.ext, account: session.account, serverUrl: serverUrl)
                                let fileNamePath = utilityFileSystem.getRelativeFilePath(String(describing: fileName), serverUrl: serverUrl, session: session)

                                await createDocument.createDocument(controller: controller, fileNamePath: fileNamePath, fileName: String(describing: fileName), editorId: "collabora", templateId: templates.selectedTemplate.identifier, account: session.account)
                            }
                        }
                    )
                )

                actions.append(
                    NCMenuAction(
                        title: NSLocalizedString("_create_new_spreadsheet_", comment: ""),
                        icon: utility.loadImage(named: "tablecells", colors: [NCBrandColor.shared.spreadsheetIconColor]),
                        sender: sender,
                        action: { _ in
                            Task { @MainActor in
                                let createDocument = NCCreate()
                                let templates = await createDocument.getTemplate(editorId: "collabora", templateId: "spreadsheet", account: session.account)
                                let fileName = await NCNetworking.shared.createFileName(fileNameBase: NSLocalizedString("_untitled_", comment: "") + "." + templates.ext, account: session.account, serverUrl: serverUrl)
                                let fileNamePath = utilityFileSystem.getRelativeFilePath(String(describing: fileName), serverUrl: serverUrl, session: session)

                                await createDocument.createDocument(controller: controller, fileNamePath: fileNamePath, fileName: String(describing: fileName), editorId: "collabora", templateId: templates.selectedTemplate.identifier, account: session.account)
                            }
                        }
                    )
                )

                actions.append(
                    NCMenuAction(
                        title: NSLocalizedString("_create_new_presentation_", comment: ""),
                        icon: utility.loadImage(named: "play.rectangle", colors: [NCBrandColor.shared.presentationIconColor]),
                        sender: sender,
                        action: { _ in
                            Task { @MainActor in
                                let createDocument = NCCreate()
                                let templates = await createDocument.getTemplate(editorId: "collabora", templateId: "presentation", account: session.account)
                                let fileName = await NCNetworking.shared.createFileName(fileNameBase: NSLocalizedString("_untitled_", comment: "") + "." + templates.ext, account: session.account, serverUrl: serverUrl)
                                let fileNamePath = utilityFileSystem.getRelativeFilePath(String(describing: fileName), serverUrl: serverUrl, session: session)

                                await createDocument.createDocument(controller: controller, fileNamePath: fileNamePath, fileName: String(describing: fileName), editorId: "collabora", templateId: templates.selectedTemplate.identifier, account: session.account)
                            }
                        }
                    )
                )
            }
        }

        controller.presentMenu(with: actions, controller: controller, sender: sender)
    }
}
