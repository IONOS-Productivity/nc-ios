//
//  MarketsConfiguration.swift
//  Nextcloud
//
//  Created by Mariia Tsariuk on 04.06.2026.
//  Copyright © 2026 STRATO GmbH. All rights reserved.
//

import Foundation

struct MarketsConfigurationLoader {

    static func loadConfiguration() -> MarketsConfiguration {
        guard let url = Bundle.main.url(forResource: "marketsConfig", withExtension: "json") else {
            assertionFailure("Critical Error: 'marketsConfig.json' could not be found in the main bundle.")
            return MarketsConfiguration(login: [], staticLinks: [])
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let configuration = try decoder.decode(MarketsConfiguration.self, from: data)

            if configuration.login.filter({ $0.countryCode == MarketsConfiguration.fallback }).count == 0 {
                assertionFailure("Critical Error: 'marketsConfig.json' must contain a fallback entry for login configuration.")
            }

            if configuration.staticLinks.filter({ $0.language == MarketsConfiguration.fallback }).count == 0 {
                assertionFailure("Critical Error: 'marketsConfig.json' must contain a fallback entry for static links configuration.")
            }

            return configuration
        } catch {
            assertionFailure("Critical Error: 'marketsConfig.json' has wrong format.")
            return MarketsConfiguration(login: [], staticLinks: [])
        }
    }
}

struct MarketsConfiguration: Decodable {
    static let fallback = "fallback"

    let login: [LoginConfiguration]
    let staticLinks: [StaticLinksConfiguration]
}

struct LoginConfiguration: Decodable {
    let countryCode: String
    let loginUrl: String
}

struct StaticLinksConfiguration: Decodable {
    let language: String
    let privacyPolicyUrl: String
    let acknowledgementsUrl: String
}
