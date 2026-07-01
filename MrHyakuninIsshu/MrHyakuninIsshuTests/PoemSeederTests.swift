//
//  PoemSeederTests.swift
//  MrHyakuninIsshuTests
//

import Testing
import Foundation
import SwiftData
@testable import MrHyakuninIsshu

struct PoemSeederTests {

    @MainActor
    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([Card.self, TagGroup.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test @MainActor func seedsAllHundredCards() throws {
        let context = try makeInMemoryContext()

        PoemSeeder.seedIfNeeded(context: context)

        let cards = try context.fetch(FetchDescriptor<Card>(sortBy: [SortDescriptor(\.number)]))
        #expect(cards.count == 100)
        #expect(cards.map(\.number) == Array(1...100))
        #expect(cards.first?.upperPhraseID == "poem_1_upper")
        #expect(cards.first?.lowerPhraseID == "poem_1_lower")
        #expect(cards.last?.upperPhraseID == "poem_100_upper")
        #expect(cards.last?.lowerPhraseID == "poem_100_lower")
    }

    @Test @MainActor func doesNotDuplicateOnSecondCall() throws {
        let context = try makeInMemoryContext()

        PoemSeeder.seedIfNeeded(context: context)
        PoemSeeder.seedIfNeeded(context: context)

        let count = try context.fetchCount(FetchDescriptor<Card>())
        #expect(count == 100)
    }
}
