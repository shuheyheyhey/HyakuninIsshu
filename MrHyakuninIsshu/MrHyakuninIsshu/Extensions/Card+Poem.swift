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
}
