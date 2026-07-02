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
            NavigationLink {
                GroupDetailView(group: nil)
            } label: {
                GroupRow(name: "全カード", cardCount: allCards.count)
            }
            .listRowBackground(Color(hex: "#8E8E93").opacity(0.3))
            ForEach(groups) { group in
                NavigationLink {
                    GroupDetailView(group: group)
                } label: {
                    GroupRow(name: group.name, cardCount: group.cards.count)
                }
                .listRowBackground(Color(hex: group.colorHex).opacity(0.3))
            }
        }
        .navigationTitle("ミスター百人一首")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    GroupEditView()
                } label: {
                    Label("グループを追加", systemImage: "plus")
                }
            }
        }
    }
}

private struct GroupRow: View {
    let name: String
    let cardCount: Int

    var body: some View {
        HStack {
            Text(name)
                .font(.headline)
            Spacer()
            Text("\(cardCount)枚")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .modelContainer(for: [Card.self, TagGroup.self], inMemory: true)
}
