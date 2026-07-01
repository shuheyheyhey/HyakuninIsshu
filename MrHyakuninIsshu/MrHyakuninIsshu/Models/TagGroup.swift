//
//  TagGroup.swift
//  MrHyakuninIsshu
//

import Foundation
import SwiftData

@Model
final class TagGroup {
    var id: UUID
    var name: String
    var colorHex: String
    var sortOrder: Int
    @Relationship(deleteRule: .nullify, inverse: \Card.groups) var cards: [Card]

    init(id: UUID = UUID(), name: String, colorHex: String, sortOrder: Int, cards: [Card] = []) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.cards = cards
    }
}
