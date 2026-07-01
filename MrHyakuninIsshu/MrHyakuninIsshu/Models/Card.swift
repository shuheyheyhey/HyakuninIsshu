//
//  Card.swift
//  MrHyakuninIsshu
//

import Foundation
import SwiftData

@Model
final class Card {
    @Attribute(.unique) var number: Int
    var upperPhraseID: String
    var lowerPhraseID: String
    var groups: [TagGroup]

    init(number: Int, upperPhraseID: String, lowerPhraseID: String, groups: [TagGroup] = []) {
        self.number = number
        self.upperPhraseID = upperPhraseID
        self.lowerPhraseID = lowerPhraseID
        self.groups = groups
    }
}
