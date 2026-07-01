//
//  MrHyakuninIsshuApp.swift
//  MrHyakuninIsshu
//
//  Created by 3toshu on 2026/07/01.
//

import SwiftUI
import SwiftData

@main
struct MrHyakuninIsshuApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Card.self,
            TagGroup.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        PoemSeeder.seedIfNeeded(context: sharedModelContainer.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
