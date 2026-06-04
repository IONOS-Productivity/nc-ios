//
//  MarketsConfiguration.swift
//  Nextcloud
//
//  Created by Mariia Tsariuk on 04.06.2026.
//  Copyright © 2026 STRATO GmbH. All rights reserved.
//

import Foundation

struct MarketsConfigurations: Decodable {
    var configurations: [MarketConfiguration] = []

    init() {
        self.configurations = loadConfigurations()
    }

    private func loadConfigurations() -> [MarketConfiguration] {
        guard let url = Bundle.main.url(forResource: "marketsConfig", withExtension: "json") else {
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let configurations = try decoder.decode([MarketConfiguration].self, from: data)

            return configurations
        } catch {
            return []
        }
    }
}

struct MarketConfiguration: Decodable {
    let countryCode: String
    let loginUrl: String
    let privacyPolicyUrl: String
}
