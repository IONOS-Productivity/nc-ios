// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: STRATO GmbH
// SPDX-FileCopyrightText: 2020 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

protocol HiDriveCollectionViewCommonSelectToolbarDelegate: AnyObject {
    func selectAll()
    func delete()
    func move()
    func share()
    func recover()
    func saveAsAvailableOffline(isAnyOffline: Bool)
    func lock(isAnyLocked: Bool)
    func toolbarWillAppear()
    func toolbarWillDisappear()
}

extension HiDriveCollectionViewCommonSelectToolbarDelegate {
    func selectAll() { }
    func delete() { }
    func move() { }
    func share() { }
    func recover() { }
    func saveAsAvailableOffline(isAnyOffline: Bool) { }
    func lock(isAnyLocked: Bool) { }
    func toolbarWillAppear() { }
    func toolbarWillDisappear() { }
}
