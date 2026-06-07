//
//  MarketsConfiguration.swift
//  Nextcloud
//
//  Created by Mariia Tsariuk on 04.06.2026.
//  Copyright © 2026 STRATO GmbH. All rights reserved.
//

import Foundation

struct MarketsConfigurationLoader {

    static func loadConfiguration() -> MarketsConfiguration? {
        guard let url = Bundle.main.url(forResource: "marketsConfig", withExtension: "json") else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let configuration = try decoder.decode(MarketsConfiguration.self, from: data)

            return configuration
        } catch {
            return nil
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
