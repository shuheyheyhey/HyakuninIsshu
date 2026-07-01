//
//  GroupEditView.swift
//  MrHyakuninIsshu
//

import SwiftUI
import SwiftData

struct GroupEditView: View {
    @Query(sort: \Card.number) private var cards: [Card]

    private let columns = [GridItem(.adaptive(minimum: 90), spacing: 8)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(cards) { card in
                    CardView(card: card)
                }
            }
            .padding()
        }
        .navigationTitle("グループを編集")
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
