// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2025 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation
import SwiftUI
import RealmSwift
import NextcloudKit

/// A modal SwiftUI view responsible for maintenance database
struct Maintenance: View {
    let onCompleted: () -> Void

    var body: some View {
        ZStack {
            Image(.gradientBackground)
                .resizable()
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()

                Image(.ionosLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 320, height: 40)
                    .foregroundColor(.white)

                Text("_opt_in_pro_")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.white)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .padding(.top, 16)

                Spacer()
            }
            .task {
                await startMaintenance()
            }
        }
        .preferredColorScheme(.dark)
    }

    /// Executes the maintenance.
    private func startMaintenance() async {
        do {
            try NCManageDatabase.shared.compactRealm()
        } catch {
            nkLog(tag: NCGlobal.shared.logTagDatabase, emoji: .error, message: "Realm compaction failed: \(error.localizedDescription)")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onCompleted()
        }
    }
}
