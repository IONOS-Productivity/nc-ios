// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2022 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import UIKit

extension UINavigationController {

    // https://stackoverflow.com/questions/6131205/how-to-find-topmost-view-controller-on-ios
    override func topMostViewController() -> UIViewController {
        return self.visibleViewController!.topMostViewController()
    }

    func setNavigationBarAppearance(textColor: UIColor = NCBrandColor.shared.textColor, backgroundColor: UIColor? = NCBrandColor.shared.appBackgroundColor) {
        let appearance = UINavigationBarAppearance()

        appearance.configureWithTransparentBackground()
        if topViewController is NCMedia {
            // transparent
        } else {
            appearance.backgroundColor = backgroundColor
        }
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()
        appearance.titleTextAttributes = [.foregroundColor: textColor]

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.compactScrollEdgeAppearance = appearance

        navigationBar.tintColor = NCBrandColor.shared.iconImageColor
        navigationBar.prefersLargeTitles = false
    }
}
