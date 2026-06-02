//
//  DeviceRegionDeterminer.swift
//  Nextcloud
//
//  Created by Mariia Tsariuk on 02.06.2026.
//  Copyright © 2026 STRATO GmbH. All rights reserved.
//

import Foundation

struct DeviceRegionDeterminer {

    func getDeviceRegion() -> String? {
        if let regionCode = Locale.current.region?.identifier {
            return regionCode.uppercased()
        }

        let identifier = Locale.current.identifier
        if let regionFromId = extractRegion(from: identifier) {
            return regionFromId.uppercased()
        }

        if let preferredLanguage = Locale.preferredLanguages.first,
           let regionFromLang = extractRegion(from: preferredLanguage) {
            return regionFromLang.uppercased()
        }

        return nil
    }

    private func extractRegion(from identifier: String) -> String? {
        // Split by common delimiters used in locale formats
        let components = identifier.replacingOccurrences(of: "-", with: "_").components(separatedBy: "_")

        for component in components.reversed() {
            if component.count == 2 && component.rangeOfCharacter(from: CharacterSet.uppercaseLetters.inverted) == nil {
                return component
            }
        }
        return nil
    }
}
