//
//  GroupEditView.swift
//  MrHyakuninIsshu
//

import SwiftUI
import SwiftData

struct GroupEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Card.number) private var cards: [Card]
    @Query(sort: \TagGroup.sortOrder) private var existingGroups: [TagGroup]

    private let existingGroup: TagGroup?

    @State private var name: String
    @State private var color: Color
    @State private var selectedCardIDs: Set<PersistentIdentifier>
    @State private var searchText: String = ""

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 8)]

    init(existingGroup: TagGroup? = nil) {
        self.existingGroup = existingGroup
        _name = State(initialValue: existingGroup?.name ?? "")
        _color = State(initialValue: existingGroup.map { Color(hex: $0.colorHex) } ?? .blue)
        _selectedCardIDs = State(
            initialValue: Set(existingGroup?.cards.map(\.persistentModelID) ?? [])
        )
    }

    private var isSaveDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedCardIDs.isEmpty
    }

    private var filteredCards: [Card] {
        cards.filtered(bySearchText: searchText)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("グループ名", text: $name)
                        .textFieldStyle(.roundedBorder)
                    ColorPicker("グループカラー", selection: $color)
                }
                .padding(.horizontal)

                Text("\(selectedCardIDs.count)件選択中")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(filteredCards) { card in
                        CardView(card: card, isSelected: selectedCardIDs.contains(card.persistentModelID))
                            .onTapGesture {
                                toggleSelection(of: card)
                            }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(existingGroup == nil ? "グループを作成" : "グループを編集")
        .searchable(text: $searchText, prompt: "カードを検索")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    save()
                }
                .disabled(isSaveDisabled)
            }
        }
    }

    private func toggleSelection(of card: Card) {
        let id = card.persistentModelID
        if selectedCardIDs.contains(id) {
            selectedCardIDs.remove(id)
        } else {
            selectedCardIDs.insert(id)
        }
    }

    private func save() {
        let selectedCards = cards.filter { selectedCardIDs.contains($0.persistentModelID) }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existingGroup {
            existingGroup.name = trimmedName
            existingGroup.colorHex = color.toHex()
            existingGroup.cards = selectedCards
        } else {
            let nextSortOrder = (existingGroups.map(\.sortOrder).max() ?? -1) + 1
            let newGroup = TagGroup(
                name: trimmedName,
                colorHex: color.toHex(),
                sortOrder: nextSortOrder,
                cards: selectedCards
            )
            modelContext.insert(newGroup)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        GroupEditView()
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
