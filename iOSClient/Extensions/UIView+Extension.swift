//
//  UIView+Extension.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 14/12/2022.
//  Copyright © 2020 Marino Faggiana. All rights reserved.
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

import Foundation
import UIKit

extension UIView {
    func makeCircularBackground(withColor backgroundColor: UIColor) {
        self.backgroundColor = backgroundColor
        self.layer.cornerRadius = self.frame.size.width / 2
        self.layer.masksToBounds = true
    }

    var bottomCenter: CGRect {
        return CGRect(origin: CGPoint(x: center.x, y: bounds.height), size: CGSizeZero)
    }

    func isInFront(of other: UIView) -> Bool {
        if let w1 = window, let w2 = other.window, w1 !== w2 {
            return w1.windowLevel > w2.windowLevel
        }
        if other.isDescendant(of: self) { return false }
        if isDescendant(of: other) { return true }

        var childA: UIView = self
        while let parent = childA.superview {
            if other.isDescendant(of: parent) {
                var childB: UIView = other
                while childB.superview !== parent { childB = childB.superview! }
                let order = parent.subviews
                return (order.firstIndex(of: childA) ?? 0) > (order.firstIndex(of: childB) ?? 0)
            }
            childA = parent
        }
        return false
    }
}
