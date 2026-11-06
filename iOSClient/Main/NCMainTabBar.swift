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

    private let backgroundTag = 99
    private let menuPlusButtonTag = 98
    private let menuAnchorTag = 97

    private var configuredItems: [UITabBarItem] = []

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

        changeTheming()

        if #available(iOS 17.0, *) {
                    registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _: UITraitCollection) in
                        self.applyItemColors()
                    }
                }
    }

    @objc func changeTheming() {
        if !usesLiquidGlass {
            layer.shadowOffset = CGSize(width: 0, height: 0)
            layer.shadowRadius = 2.0
            layer.shadowOpacity = 0.5
        }
        let activeColor = UIColor(resource: .Tabbar.activeItem)
        let inactiveColor = UIColor(resource: .Tabbar.inactiveItem)
        tintColor = activeColor
        unselectedItemTintColor = inactiveColor

        let appearance = UITabBarAppearance()
        if usesLiquidGlass {
            appearance.configureWithDefaultBackground()
        } else {
            appearance.configureWithTransparentBackground()
        }

        for itemAppearance in [appearance.stackedLayoutAppearance,
                               appearance.inlineLayoutAppearance,
                               appearance.compactInlineLayoutAppearance] {
            itemAppearance.normal.iconColor = inactiveColor
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: inactiveColor]
            itemAppearance.selected.iconColor = activeColor
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: activeColor]
        }

        standardAppearance = appearance
        scrollEdgeAppearance = appearance

        applyItemColors()
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
        if let button = self.viewWithTag(menuPlusButtonTag), button.frame.contains(point) {
            return true
        }
        return false
    }

    // MARK: - Center button taps outside the tab bar (iOS 26)

    // On iOS 26 the tab bar sits in a container that only covers the bar itself,
    // so touches on the part of the center button above the bar never reach it
    // and go to the content below (cell tap, long-press menu, ...).
    // A transparent overlay on the tab bar controller's view claims exactly the
    // points covered by the button during hit-testing and hands the touch to the
    // real button, so the content below is never involved.

    private lazy var centerButtonOverlay: CenterButtonTouchOverlay = {
        let overlay = CenterButtonTouchOverlay()
        overlay.backgroundColor = .clear
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.isAccessibilityElement = false
        overlay.buttonProvider = { [weak self] in
            guard let self else { return nil }
            return self.viewWithTag(self.menuPlusButtonTag) as? UIButton
        }
        return overlay
    }()

    override func didMoveToWindow() {
        super.didMoveToWindow()
        installCenterButtonOverlayIfNeeded()
    }

    private func installCenterButtonOverlayIfNeeded() {
        // Find the UITabBarController's root view among our ancestors.
        var view: UIView? = superview
        while let current = view, !(current.next is UITabBarController) {
            view = current.superview
        }
        guard let host = view else { return }

        if centerButtonOverlay.superview !== host {
            centerButtonOverlay.removeFromSuperview()
            centerButtonOverlay.frame = host.bounds
            host.addSubview(centerButtonOverlay)
        }
        // Must stay the top-most subview, above content and the tab bar container.
        if host.subviews.last !== centerButtonOverlay {
            host.bringSubviewToFront(centerButtonOverlay)
        }
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
    private let itemImageNames: [Int: String] = [0: "home", 1: "media", 3: "shares", 4: "favorites"]

    private func configureItemsIfNeeded() {
        guard let items, items.count >= 5, items != configuredItems else { return }
        configuredItems = items

        items[0].title = NSLocalizedString("_home_", comment: "")         // File
        items[1].title = NSLocalizedString("_media_", comment: "")        // Media
        items[3].title = NSLocalizedString("_list_shares_", comment: "")  // Shares
        items[4].title = NSLocalizedString("_favorites_", comment: "")    // Favorite

        // + (placeholder under the center button)
        items[2].title = ""
        items[2].image = nil
        items[2].isEnabled = false

        applyItemColors()
    }

    /// Liquid Glass ignores unselectedItemTintColor and the appearance "normal"
    /// colors, so unselected images are pre-colored and marked .alwaysOriginal.
    /// Selected images stay template images and take the tab bar tintColor.
    private func applyItemColors() {
        guard let items, items.count >= 5 else { return }

        let inactiveColor = UIColor(resource: .Tabbar.inactiveItem)
        let inactive = inactiveColor.resolvedColor(with: traitCollection)
        let active = UIColor(resource: .Tabbar.activeItem)

        for (index, name) in itemImageNames {
            guard let base = UIImage(named: name) else { continue }
            let item = items[index]

            if usesLiquidGlass {
                item.image = base.withTintColor(inactive, renderingMode: .alwaysOriginal)
                item.selectedImage = base.withRenderingMode(.alwaysTemplate)
            } else {
                item.image = base
                item.selectedImage = base
            }

            item.setTitleTextAttributes([.foregroundColor: inactive], for: .normal)
            item.setTitleTextAttributes([.foregroundColor: active], for: .selected)
        }
    }

    // MARK: - Center button

    private func layoutCenterButton() {
        let centerButton = (viewWithTag(menuPlusButtonTag) as? UIButton) ?? makeCenterButton()

        centerButton.frame = CGRect(x: (bounds.width / 2) - (centerButtonHeight / 2),
                                    y: centerButtonY,
                                    width: centerButtonHeight,
                                    height: centerButtonHeight)
        centerButton.layer.cornerRadius = centerButtonHeight / 2.0

        // Keep it above the system (glass) views
        bringSubviewToFront(centerButton)

        // Invisible menu anchor just above the button: the menu is presented from
        // here, so UIKit hides this view (not the "+") and the menu opens above
        // the button instead of covering it.
        let anchor = (viewWithTag(menuAnchorTag) as? UIButton) ?? makeMenuAnchor()
        anchor.frame = CGRect(x: centerButton.frame.minX,
                              y: centerButton.frame.minY - 8,
                              width: centerButton.frame.width,
                              height: 1)

        installCenterButtonOverlayIfNeeded()
    }

    private func makeCenterButton() -> NCMenuPlusButton {
        let buttonSize: CGFloat = 44
        let plusConfiguration = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let plusImage = UIImage(systemName: "plus", withConfiguration: plusConfiguration)?.withRenderingMode(.alwaysTemplate)

        let menuPlusButton = NCMenuPlusButton(type: .system)
        menuPlusButton.setImage(plusImage, for: .normal)
        menuPlusButton.contentHorizontalAlignment = .center
        menuPlusButton.contentVerticalAlignment = .center
        menuPlusButton.layer.cornerRadius = buttonSize / 2
        menuPlusButton.layer.masksToBounds = false
        menuPlusButton.layer.shadowColor = UIColor.black.cgColor
        menuPlusButton.layer.shadowOpacity = 0.5
        menuPlusButton.layer.shadowRadius = 3.0
        menuPlusButton.layer.shadowOffset = CGSize(width: 0, height: 0)

        menuPlusButton.setPlusButtonColor(UIColor(resource: .Tabbar.fabButton))
        menuPlusButton.showsMenuAsPrimaryAction = false // menu is shown from the anchor
        menuPlusButton.translatesAutoresizingMaskIntoConstraints = false
        menuPlusButton.accessibilityLabel = NSLocalizedString("_add_", comment: "")
        menuPlusButton.tag = menuPlusButtonTag

        menuPlusButton.action(for: .touchUpInside) { [weak self, weak menuPlusButton] _ in
            guard let self, let menuPlusButton,
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

                    let anchor = self.usesLiquidGlass ? self.viewWithTag(self.menuAnchorTag) as? UIButton : nil
                    if self.menuPlus == nil {
                        self.menuPlus = NCContextMenuPlus(menuButton: menuPlusButton, menuAnchor: anchor, controller: controller)
                    } else {
                        self.menuPlus?.menuButton = menuPlusButton
                        self.menuPlus?.menuAnchor = anchor
                    }
                    let session = NCSession.shared.getSession(account: controller.account)
                    await self.menuPlus?.create(session: session)
                }
            }
        }

        addSubview(menuPlusButton)
        return menuPlusButton
    }

    private func makeMenuAnchor() -> UIButton {
        let anchor = MenuAnchorButton(type: .custom)
        anchor.tag = menuAnchorTag
        anchor.backgroundColor = .clear
        anchor.isAccessibilityElement = false
        addSubview(anchor)
        return anchor
    }

    func getHeight() -> CGFloat {
        return (frame.size.height - centerButtonY)
    }
}

/// Full-screen, transparent view on the tab bar controller's view.
/// For points on the center button it returns the button, unless something is
/// drawn in front of the button there (the "+" menu, burger menu, ...), in which
/// case that view keeps the touch. Everywhere else it returns nil, so touches
/// pass through untouched.
private final class CenterButtonTouchOverlay: UIView {
    var buttonProvider: (() -> UIButton?)?
    private var isResolving = false

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Re-entrant call from the window hit test below: behave as if absent.
        guard !isResolving else { return nil }

        guard let button = buttonProvider?(),
              let window = button.window,
              isEffectivelyVisible(button) else { return nil }

        let pointInButton = convert(point, to: button)
        guard button.bounds.contains(pointInButton) else { return nil }

        isResolving = true
        let underlying = window.hitTest(convert(point, to: window), with: event)
        isResolving = false

        if let underlying {
            // The button itself (part inside the bar) — normal case.
            if underlying.isDescendant(of: button) { return underlying }
            // Something drawn in front of the button (menu, panel, alert...).
            if underlying.isInFront(of: button) { return underlying }
        }

        // Content behind the button (list cell, ...): the button takes it.
        // NCMenuPlusButton.hitTest also returns itself while disabled.
        return button.hitTest(pointInButton, with: event) ?? button
    }

    /// The button and all its ancestors must be visible (tab bar not hidden).
    private func isEffectivelyVisible(_ view: UIView) -> Bool {
        var current: UIView? = view
        while let v = current {
            if v.isHidden || v.alpha < 0.01 { return false }
            current = v.superview
        }
        return true
    }
}

private final class MenuAnchorButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return false
    }
}

private final class NCMenuPlusButton: UIButton {
    // Keep hit testing so taps don't fall through if the button is disabled, hidden or low alpha.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let view = super.hitTest(point, with: event) {
            return view
        }

        guard !isEnabled, !isHidden, alpha >= 0.01, bounds.contains(point) else {
            return nil
        }

        return self
    }

    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard isEnabled else { return nil }

        return super.contextMenuInteraction(interaction, configurationForMenuAtLocation: location)
    }
}

extension UIButton {
    func setPlusButtonColor(_ color: UIColor) {
        backgroundColor = color
        tintColor = .white
    }
}
