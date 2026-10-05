//
//  NCMainTabBar.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 06/01/2020.
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

class NCMainTabBar: UITabBar {

    private let heightForDevicesWithRectCornersDisplay: CGFloat = 64.0

    private var fillColor: UIColor!
    private let appDelegate = (UIApplication.shared.delegate as? AppDelegate)!
    private let centerButtonY: CGFloat = -28
    private let centerButtonHeight: CGFloat = 57
    public var color = NCBrandColor.shared.customer

    private var menuPlus: NCContextMenuPlus?

    // Tags for the views WE own. Never touch other subviews:
    // on iOS 26 they contain the Liquid Glass platter with the item views.
    private let backgroundTag = 98
    private let centerButtonTag = 99

    private var configuredItems: [UITabBarItem] = []

    /// true when running on iOS 26+ with the new Liquid Glass design active
    private var usesLiquidGlass: Bool {
        if #available(iOS 26.0, *) {
            let compat = Bundle.main.object(forInfoDictionaryKey: "UIDesignRequiresCompatibility") as? Bool ?? false
            return !compat
        }
        return false
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        guard !UIDevice.current.hasComplexSaveArea else {
            return super.sizeThatFits(size)
        }

        var sizeThatFits = super.sizeThatFits(size)
        sizeThatFits.height = heightForDevicesWithRectCornersDisplay
        return sizeThatFits
    }

    private var customBackgroundColor: UIColor? {
        UIColor(named: "Tabbar/Background")
    }

    public var menuRect: CGRect {
        let tabBarItemWidth = Int(self.frame.size.width) / max(self.items?.count ?? 1, 1)
        let rect = CGRect(x: 0, y: -5, width: tabBarItemWidth, height: Int(self.frame.size.height))
        return rect
    }

    // MARK: - Life Cycle

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        if !usesLiquidGlass {
            // Hide the system background so our notched shape is visible.
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            standardAppearance = appearance
            scrollEdgeAppearance = appearance
        }

        changeTheming()
    }

    @objc func changeTheming() {
        if !usesLiquidGlass {
            layer.shadowOffset = CGSize(width: 0, height: 0)
            layer.shadowRadius = 2.0
            layer.shadowOpacity = 0.5
        }
        tintColor = UIColor(resource: .Tabbar.activeItem)
    }

    override var backgroundColor: UIColor? {
        get {
            return self.fillColor
        }
        set {
            fillColor = newValue
            self.setNeedsLayout()
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if self.bounds.contains(point) {
            return true
        }
        if let button = self.viewWithTag(centerButtonTag), button.frame.contains(point) {
            return true
        }
        return false
    }

    override var traitCollection: UITraitCollection {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return super.traitCollection }
        return UITraitCollection(traitsFrom: [super.traitCollection, UITraitCollection(horizontalSizeClass: .compact)])
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        configureItemsIfNeeded()
        layoutBackgroundShape()
        layoutCenterButton()
    }

    private func layoutBackgroundShape() {
        // With Liquid Glass the system draws the glass background; don't cover it.
        guard !usesLiquidGlass else {
            viewWithTag(backgroundTag)?.removeFromSuperview()
            return
        }

        let backgroundView: UIView
        if let existing = viewWithTag(backgroundTag) {
            backgroundView = existing
        } else {
            backgroundView = UIView()
            backgroundView.tag = backgroundTag
            backgroundView.isUserInteractionEnabled = false
            insertSubview(backgroundView, at: 0)
        }

        backgroundView.frame = bounds
        backgroundView.backgroundColor = customBackgroundColor

        let maskLayer = (backgroundView.layer.mask as? CAShapeLayer) ?? CAShapeLayer()
        maskLayer.path = createPath()
        backgroundView.layer.mask = maskLayer
    }

    private func createPath() -> CGPath {

        let height: CGFloat = 28
        let margin: CGFloat = 6
        let path = UIBezierPath()
        let centerWidth = self.bounds.width / 2

        path.move(to: CGPoint(x: 0, y: 0)) // start top left
        path.addLine(to: CGPoint(x: (centerWidth - height - margin), y: 0)) // the beginning of the trough
        // first curve down
        path.addArc(withCenter: CGPoint(x: centerWidth, y: 0), radius: height + margin, startAngle: .pi, endAngle: 0, clockwise: false)
        // complete the rect
        path.addLine(to: CGPoint(x: self.bounds.width, y: 0))
        path.addLine(to: CGPoint(x: self.bounds.width, y: self.bounds.height))
        path.addLine(to: CGPoint(x: 0, y: self.bounds.height))
        path.close()

        return path.cgPath
    }

    // MARK: - Items

    private func configureItemsIfNeeded() {
        guard let items, items.count >= 5, items != configuredItems else { return }
        configuredItems = items

        // File
        items[0].title = NSLocalizedString("_home_", comment: "")
        items[0].image = UIImage(named: "home")
        items[0].selectedImage = items[0].image

        // Media
        items[1].title = NSLocalizedString("_media_", comment: "")
        items[1].image = UIImage(named: "media")
        items[1].selectedImage = items[1].image

        // + (placeholder under the center button)
        items[2].title = ""
        items[2].image = nil
        items[2].isEnabled = false

        // Shares
        items[3].title = NSLocalizedString("_list_shares_", comment: "")
        items[3].image = UIImage(named: "shares")
        items[3].selectedImage = items[3].image

        // Favorite
        items[4].title = NSLocalizedString("_favorites_", comment: "")
        items[4].image = UIImage(named: "favorites")
        items[4].selectedImage = items[4].image
    }

    // MARK: - Center button

    private func layoutCenterButton() {
        let centerButton = (viewWithTag(centerButtonTag) as? UIButton) ?? makeCenterButton()

        centerButton.frame = CGRect(x: (bounds.width / 2) - (centerButtonHeight / 2),
                                    y: centerButtonY,
                                    width: centerButtonHeight,
                                    height: centerButtonHeight)
        centerButton.layer.cornerRadius = centerButtonHeight / 2.0

        // Keep it above the system (glass) views
        bringSubviewToFront(centerButton)
    }

    private func makeCenterButton() -> UIButton {
        let imagePlus = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?
            .applyingSymbolConfiguration(UIImage.SymbolConfiguration(paletteColors: [.white]))

        let centerButton = UIButton(type: .custom)
        centerButton.setTitle("", for: .normal)
        centerButton.setImage(imagePlus, for: .normal)
        centerButton.backgroundColor = UIColor(resource: .Tabbar.fabButton)
        centerButton.tintColor = UIColor.white
        centerButton.tag = centerButtonTag
        centerButton.accessibilityLabel = NSLocalizedString("_accessibility_add_upload_", comment: "")
        centerButton.layer.masksToBounds = false
        centerButton.layer.shadowOffset = CGSize(width: 0, height: 0)
        centerButton.layer.shadowRadius = 3.0
        centerButton.layer.shadowOpacity = 0.5

        centerButton.action(for: .touchUpInside) { [weak self, weak centerButton] _ in
            guard let self, let centerButton,
                  let controller = self.window?.rootViewController as? NCMainTabBarController else { return }

            let serverUrl = controller.currentServerUrl()
            if let directory = NCManageDatabase.shared.getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", NCSession.shared.getSession(controller: controller).account, serverUrl)) {
                if !directory.permissions.contains("CK") {
                    let error = NKError(errorCode: NCGlobal.shared.errorInternalError, errorDescription: "_no_permission_add_file_")
                    NCContentPresenter().showWarning(error: error)
                    return
                }
            }

            let fileFolderPath = NCUtilityFileSystem().getRelativeFilePath("", serverUrl: serverUrl, session: NCSession.shared.getSession(controller: controller))
            let fileFolderName = (serverUrl as NSString).lastPathComponent
            Task {
                if let capabilities = await NCManageDatabase.shared.getCapabilities(account: controller.account) {

                    if !FileNameValidator.checkFolderPath(fileFolderPath, account: controller.account, capabilities: capabilities) {
                        controller.present(UIAlertController.warning(message: "\(String(format: NSLocalizedString("_file_name_validator_error_reserved_name_", comment: ""), fileFolderName)) \(NSLocalizedString("_please_rename_file_", comment: ""))"), animated: true)

                        return
                    }

                    if self.menuPlus == nil {
                        self.menuPlus = NCContextMenuPlus(menuButton: centerButton, controller: controller)
                    } else {
                        self.menuPlus?.menuButton = centerButton
                    }
                    let session = NCSession.shared.getSession(account: controller.account)
                    await self.menuPlus?.create(session: session)
                }
            }
        }

        addSubview(centerButton)
        return centerButton
    }

    func getHeight() -> CGFloat {
        return (frame.size.height - centerButtonY)
    }
}
