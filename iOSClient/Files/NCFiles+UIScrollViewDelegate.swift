// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2025 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

extension NCFiles {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffsetY = scrollView.contentOffset.y
        let currentTime = CACurrentMediaTime()
        let deltaY = currentOffsetY - lastOffsetY
        let deltaTime = currentTime - lastScrollTime
        let velocity = deltaTime > 0 ? deltaY / CGFloat(deltaTime) : 0
        lastOffsetY = currentOffsetY
        lastScrollTime = currentTime
    }
}
