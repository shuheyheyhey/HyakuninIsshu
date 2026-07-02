//
//  GroupDetailView.swift
//  MrHyakuninIsshu
//

import SwiftUI
import SwiftData

struct GroupDetailView: View {
    let group: TagGroup?

    @Query(sort: \Card.number) private var allCards: [Card]

    @State private var searchText: String = ""
    @State private var selectedCard: Card?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 8)]

    private var cards: [Card] {
        let groupCards: [Card]
        if let group {
            groupCards = group.cards.sorted { $0.number < $1.number }
        } else {
            groupCards = allCards
        }
        return groupCards.filtered(bySearchText: searchText)
    }

    private var colorHex: String {
        group?.colorHex ?? "#8E8E93"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(cards.count)枚")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(cards) { card in
                        Button {
                            selectedCard = card
                        } label: {
                            CardView(card: card, backgroundColor: Color(hex: colorHex).opacity(0.3))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(group?.name ?? "全カード")
        .searchable(text: $searchText, prompt: "カードを検索")
        .toolbar {
            if let group {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink("編集") {
                        GroupEditView(existingGroup: group)
                    }
                }
            }
        }
        .overlay {
            if selectedCard != nil {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedCard = nil
                    }
            }
        }
        .sheet(item: $selectedCard) { card in
            CardPreviewView(card: card, borderColorHex: colorHex)
                .presentationBackgroundInteraction(.enabled)
        }
    }
}

#Preview {
    NavigationStack {
        GroupDetailView(group: nil)
    }
    .modelContainer(previewContainer)
}

@MainActor
private let previewContainer: ModelContainer = {
    let schema = Schema([Card.self, TagGroup.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    PoemSeeder.seedIfNeeded(context: container.mainContext)
    return container
}()
