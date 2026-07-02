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
        // Resolve through `modelContext` rather than filtering the `@Query` array directly —
        // assigning objects fetched under a different context to a relationship crashes with
        // "Illegal attempt to establish a relationship... between objects in different contexts".
        let selectedCards = selectedCardIDs.compactMap { modelContext.model(for: $0) as? Card }
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
                sortOrder: nextSortOrder
            )
            // Insert before assigning `cards` — until it's inserted, `newGroup` doesn't belong to
            // any context, and linking it to already-managed Cards crashes with the same
            // "different contexts" error the Card-side fix above addresses.
            modelContext.insert(newGroup)
            newGroup.cards = selectedCards
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
