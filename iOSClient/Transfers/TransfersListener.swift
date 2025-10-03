//
//  TransfersListener.swift
//  Nextcloud
//
//  Created by Sergey Kaliberda on 23.04.2025.
//  Copyright © 2025 STRATO GmbH. All rights reserved.
//

import Combine

class TransfersListener {

    static let shared = TransfersListener()

    private var timer: Timer?

    let activeTransfersListener: PassthroughSubject<Void, Never> = .init()
    private(set) var areActiveTransfersPresent: Bool = false

    init() {
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            self.timer?.invalidate()
            self.timer = nil
        }

        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if UIApplication.shared.applicationState == .active {
                    self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
                        self.onTimerTick()
                    })
                }
            }
        }
    }

    private func onTimerTick() {
        areActiveTransfersPresent = calculatePresenceOfActiveTransfers()
        activeTransfersListener.send()
    }

    private func calculatePresenceOfActiveTransfers() -> Bool {
        return false
//        let resultsCount = NCManageDatabase.shared.getResultsMetadatas(predicate: NSPredicate(format: "status != %i", NCGlobal.shared.metadataStatusNormal))?.count ?? 0
//        return resultsCount > 0
    }
}
