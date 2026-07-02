//
//  Card+Poem.swift
//  MrHyakuninIsshu
//

import Foundation

extension Card {
    var upperText: String {
        NSLocalizedString("\(upperPhraseID).text", tableName: "Poems", bundle: .main, comment: "")
    }

    var lowerText: String {
        NSLocalizedString("\(lowerPhraseID).text", tableName: "Poems", bundle: .main, comment: "")
    }

    var upperReading: String {
        NSLocalizedString("\(upperPhraseID).reading", tableName: "Poems", bundle: .main, comment: "")
    }

    var lowerReading: String {
        NSLocalizedString("\(lowerPhraseID).reading", tableName: "Poems", bundle: .main, comment: "")
    }
}

extension Sequence where Element == Card {
    func filtered(bySearchText searchText: String) -> [Card] {
        guard !searchText.isEmpty else { return Array(self) }
        return filter { card in
            String(card.number).contains(searchText)
            || card.upperText.contains(searchText)
            || card.lowerText.contains(searchText)
        }
    }
}
