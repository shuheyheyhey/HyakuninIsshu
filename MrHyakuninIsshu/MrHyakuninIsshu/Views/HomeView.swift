//
//  HomeView.swift
//  MrHyakuninIsshu
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var allCards: [Card]
    @Query(sort: \TagGroup.sortOrder) private var groups: [TagGroup]

    var body: some View {
        List {
            GroupRow(name: "全カード", cardCount: allCards.count, colorHex: "#8E8E93")
            ForEach(groups) { group in
                GroupRow(name: group.name, cardCount: group.cards.count, colorHex: group.colorHex)
            }
        }
        .navigationTitle("ミスター百人一首")
    }
}

private struct GroupRow: View {
    let name: String
    let cardCount: Int
    let colorHex: String

    var body: some View {
        HStack {
            Text(name)
                .font(.headline)
            Spacer()
            Text("\(cardCount)枚")
                .foregroundStyle(.secondary)
        }
        .listRowBackground(Color(hex: colorHex).opacity(0.3))
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .modelContainer(for: [Card.self, TagGroup.self], inMemory: true)
}
