//
//  GroupEditView.swift
//  MrHyakuninIsshu
//

import SwiftUI
import SwiftData

struct GroupEditView: View {
    @Query(sort: \Card.number) private var cards: [Card]

    @State private var name: String = ""
    @State private var color: Color = .blue
    @State private var selectedCardIDs: Set<PersistentIdentifier> = []

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 8)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("グループ名", text: $name)
                        .textFieldStyle(.roundedBorder)
                    ColorPicker("グループカラー", selection: $color)
                }
                .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(cards) { card in
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
        .navigationTitle("グループを作成")
    }

    private func toggleSelection(of card: Card) {
        let id = card.persistentModelID
        if selectedCardIDs.contains(id) {
            selectedCardIDs.remove(id)
        } else {
            selectedCardIDs.insert(id)
        }
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
