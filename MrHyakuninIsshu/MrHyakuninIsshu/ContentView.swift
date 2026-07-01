//
//  ContentView.swift
//  MrHyakuninIsshu
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Card.number) private var cards: [Card]

    var body: some View {
        NavigationStack {
            List(cards) { card in
                Text("第\(card.number)首")
            }
            .navigationTitle("ミスター百人一首")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Card.self, inMemory: true)
}
