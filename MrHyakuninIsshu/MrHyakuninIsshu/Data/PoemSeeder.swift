//
//  PoemSeeder.swift
//  MrHyakuninIsshu
//

import Foundation
import SwiftData

enum PoemSeeder {
    static func seedIfNeeded(context: ModelContext) {
        let existingCount = (try? context.fetchCount(FetchDescriptor<Card>())) ?? 0
        guard existingCount == 0 else { return }

        for number in 1...100 {
            let card = Card(
                number: number,
                upperPhraseID: "poem_\(number)_upper",
                lowerPhraseID: "poem_\(number)_lower"
            )
            context.insert(card)
        }
    }
}
