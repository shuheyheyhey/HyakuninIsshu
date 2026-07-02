//
//  PlaySessionModelTests.swift
//  MrHyakuninIsshuTests
//

import Testing
import Foundation
@testable import MrHyakuninIsshu

@MainActor
private final class FakeSpeechService: SpeechServicing {
    private(set) var playedPhraseIDs: [String] = []
    private(set) var stopCallCount = 0
    private var pendingContinuation: CheckedContinuation<SpeechService.PlaybackOutcome, Never>?

    func playAsync(phraseID: String, readingText: String) async -> SpeechService.PlaybackOutcome {
        playedPhraseIDs.append(phraseID)
        return await withCheckedContinuation { self.pendingContinuation = $0 }
    }

    func stop() {
        stopCallCount += 1
        pendingContinuation?.resume(returning: .interrupted)
        pendingContinuation = nil
    }

    /// Test-only: let the currently in-flight `playAsync` call complete naturally.
    func finishCurrentPlay() {
        pendingContinuation?.resume(returning: .finished)
        pendingContinuation = nil
    }
}

@MainActor
private func makeCards(_ count: Int) -> [Card] {
    (1...count).map { Card(number: $0, upperPhraseID: "poem_\($0)_upper", lowerPhraseID: "poem_\($0)_lower") }
}

/// Polls `condition` by repeatedly yielding until it becomes true, instead of guessing a fixed
/// number of yields — the number of scheduling hops needed to observe an async state change
/// depends on how many nested Tasks/continuations are involved and isn't safe to hardcode.
@MainActor
private func waitUntil(
    timeout: TimeInterval = 2.0,
    _ condition: @autoclosure () -> Bool
) async {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        if Date() >= deadline { return }
        await Task.yield()
    }
}

struct PlaySessionModelTests {

    @MainActor
    @Test func shuffleInvokedOncePerStartNotOnResume() async {
        var shuffleCallCount = 0
        let speech = FakeSpeechService()
        let model = PlaySessionModel(
            speechService: speech,
            shuffle: { cards in shuffleCallCount += 1; return cards },
            intervalSleep: { _ in }
        )
        let cards = makeCards(2)

        model.start(cards: cards, upperToLowerInterval: 0, interCardInterval: 0)
        #expect(shuffleCallCount == 1)

        await waitUntil(speech.playedPhraseIDs.count == 1)
        model.pause()
        #expect(model.isPaused)

        model.resume(upperToLowerInterval: 0, interCardInterval: 0)
        await waitUntil(speech.playedPhraseIDs.count == 2)

        #expect(shuffleCallCount == 1)
    }

    @MainActor
    @Test func resumeAfterPauseReplaysCurrentPhraseFromScratch() async {
        let speech = FakeSpeechService()
        let model = PlaySessionModel(speechService: speech, shuffle: { $0 }, intervalSleep: { _ in })
        let cards = makeCards(1)

        model.start(cards: cards, upperToLowerInterval: 0, interCardInterval: 0)
        await waitUntil(speech.playedPhraseIDs.count == 1)
        #expect(model.phase == .playingUpper)
        #expect(speech.playedPhraseIDs == ["poem_1_upper"])

        model.pause()
        #expect(model.isPaused)
        #expect(model.phase == .playingUpper)
        #expect(speech.stopCallCount == 1)

        model.resume(upperToLowerInterval: 0, interCardInterval: 0)
        await waitUntil(speech.playedPhraseIDs.count == 2)

        #expect(speech.playedPhraseIDs == ["poem_1_upper", "poem_1_upper"])
    }

    @MainActor
    @Test func skipDuringReadingAdvancesPhaseWithoutPausing() async {
        let speech = FakeSpeechService()
        let model = PlaySessionModel(speechService: speech, shuffle: { $0 }, intervalSleep: { _ in })
        let cards = makeCards(1)

        model.start(cards: cards, upperToLowerInterval: 0, interCardInterval: 0)
        await waitUntil(speech.playedPhraseIDs.count == 1)
        #expect(model.phase == .playingUpper)

        model.skip()
        await waitUntil(speech.playedPhraseIDs.count == 2)

        #expect(model.isPaused == false)
        #expect(model.phase == .playingLower)
        #expect(speech.playedPhraseIDs == ["poem_1_upper", "poem_1_lower"])
    }

    @MainActor
    @Test func skipDuringIntervalAdvancesToNextPhaseImmediately() async {
        let speech = FakeSpeechService()
        let neverEndingSleep: (TimeInterval) async -> Void = { _ in
            await withCheckedContinuation { (_: CheckedContinuation<Void, Never>) in }
        }
        let model = PlaySessionModel(speechService: speech, shuffle: { $0 }, intervalSleep: neverEndingSleep)
        let cards = makeCards(1)

        model.start(cards: cards, upperToLowerInterval: 5, interCardInterval: 0)
        await waitUntil(speech.playedPhraseIDs.count == 1)
        speech.finishCurrentPlay()
        await waitUntil(model.phase == .upperToLowerInterval)

        model.skip()
        await waitUntil(speech.playedPhraseIDs.count == 2)

        #expect(model.phase == .playingLower)
    }

    @MainActor
    @Test func skipDuringReadingBypassesTheFollowingIntervalEntirely() async {
        let speech = FakeSpeechService()
        var sleepCallCount = 0
        let countingSleep: (TimeInterval) async -> Void = { _ in
            sleepCallCount += 1
        }
        let model = PlaySessionModel(speechService: speech, shuffle: { $0 }, intervalSleep: countingSleep)
        let cards = makeCards(1)

        model.start(cards: cards, upperToLowerInterval: 5, interCardInterval: 5)
        await waitUntil(speech.playedPhraseIDs.count == 1)
        #expect(model.phase == .playingUpper)

        model.skip()
        await waitUntil(speech.playedPhraseIDs.count == 2)

        #expect(model.phase == .playingLower)
        #expect(sleepCallCount == 0)
    }

    @MainActor
    @Test func skipOnlyBypassesTheImmediateIntervalNotFutureOnes() async {
        let speech = FakeSpeechService()
        var sleepCallCount = 0
        let countingSleep: (TimeInterval) async -> Void = { _ in
            sleepCallCount += 1
        }
        let model = PlaySessionModel(speechService: speech, shuffle: { $0 }, intervalSleep: countingSleep)
        let cards = makeCards(2)

        model.start(cards: cards, upperToLowerInterval: 5, interCardInterval: 5)
        await waitUntil(speech.playedPhraseIDs.count == 1) // card 1 upper playing

        // Skip card 1's upper reading — bypasses card 1's upper→lower interval only.
        model.skip()
        await waitUntil(speech.playedPhraseIDs.count == 2) // card 1 lower playing
        #expect(sleepCallCount == 0)

        // Card 1's lower reading finishes naturally — its interCardInterval must run for real
        // (countingSleep completes instantly, so the model auto-advances once it does).
        speech.finishCurrentPlay()
        await waitUntil(speech.playedPhraseIDs.count == 3) // card 2 upper playing
        #expect(sleepCallCount == 1)
        #expect(model.currentIndex == 1)

        // Card 2's upper reading finishes naturally — its upper→lower interval must also run for
        // real, proving the bypass from the earlier skip didn't leak into later, unrelated intervals.
        speech.finishCurrentPlay()
        await waitUntil(speech.playedPhraseIDs.count == 4) // card 2 lower playing
        #expect(sleepCallCount == 2)
    }

    @MainActor
    @Test func pauseDuringIntervalHaltsAndResumeReplaysTheFullInterval() async {
        let speech = FakeSpeechService()
        var sleepCallCount = 0
        let neverEndingSleep: (TimeInterval) async -> Void = { _ in
            sleepCallCount += 1
            await withCheckedContinuation { (_: CheckedContinuation<Void, Never>) in }
        }
        let model = PlaySessionModel(speechService: speech, shuffle: { $0 }, intervalSleep: neverEndingSleep)
        let cards = makeCards(1)

        model.start(cards: cards, upperToLowerInterval: 5, interCardInterval: 0)
        await waitUntil(speech.playedPhraseIDs.count == 1)
        speech.finishCurrentPlay()
        await waitUntil(model.phase == .upperToLowerInterval)
        await waitUntil(sleepCallCount == 1)
        #expect(sleepCallCount == 1)

        model.pause()
        #expect(model.isPaused)
        #expect(model.phase == .upperToLowerInterval)

        model.resume(upperToLowerInterval: 5, interCardInterval: 0)
        await waitUntil(sleepCallCount == 2)

        // Resuming starts a brand-new wait rather than continuing the interrupted one.
        #expect(sleepCallCount == 2)
        #expect(model.phase == .upperToLowerInterval)
    }

    @MainActor
    @Test func lifecycleCompletesOnceWithoutLooping() async {
        let speech = FakeSpeechService()
        let model = PlaySessionModel(speechService: speech, shuffle: { $0 }, intervalSleep: { _ in })
        let cards = makeCards(2)

        model.start(cards: cards, upperToLowerInterval: 0, interCardInterval: 0)

        for expectedCount in 1...(cards.count * 2) {
            await waitUntil(speech.playedPhraseIDs.count == expectedCount)
            speech.finishCurrentPlay()
        }
        await waitUntil(model.isFinished)

        #expect(model.phase == .completed)
        #expect(speech.playedPhraseIDs.count == cards.count * 2)
    }

    @MainActor
    @Test func reshuffleOnlyHappensAfterFullCompletionAndNewStart() async {
        var shuffleCallCount = 0
        let speech = FakeSpeechService()
        let model = PlaySessionModel(
            speechService: speech,
            shuffle: { cards in shuffleCallCount += 1; return cards },
            intervalSleep: { _ in }
        )
        let cards = makeCards(1)

        model.start(cards: cards, upperToLowerInterval: 0, interCardInterval: 0)
        await waitUntil(speech.playedPhraseIDs.count == 1)
        speech.finishCurrentPlay()
        await waitUntil(speech.playedPhraseIDs.count == 2)
        speech.finishCurrentPlay()
        await waitUntil(model.isFinished)

        #expect(model.phase == .completed)
        #expect(shuffleCallCount == 1)

        model.start(cards: cards, upperToLowerInterval: 0, interCardInterval: 0)
        await waitUntil(model.phase == .playingUpper)

        #expect(model.currentIndex == 0)
        #expect(shuffleCallCount == 2)
    }

    @MainActor
    @Test func pauseSkipResumeAreNoOpsBeforeStartOrAfterCompletion() async {
        let speech = FakeSpeechService()
        let model = PlaySessionModel(speechService: speech, shuffle: { $0 }, intervalSleep: { _ in })

        model.pause()
        model.skip()
        model.resume(upperToLowerInterval: 0, interCardInterval: 0)

        #expect(model.phase == .notStarted)
        #expect(model.isPaused == false)
        #expect(speech.stopCallCount == 0)
    }

    @MainActor
    @Test func resetCancelsInFlightPlaybackAndClearsQueue() async {
        let speech = FakeSpeechService()
        let model = PlaySessionModel(speechService: speech, shuffle: { $0 }, intervalSleep: { _ in })
        let cards = makeCards(2)

        model.start(cards: cards, upperToLowerInterval: 0, interCardInterval: 0)
        await waitUntil(speech.playedPhraseIDs.count == 1)

        model.reset()

        #expect(model.phase == .notStarted)
        #expect(model.queue.isEmpty)
        #expect(speech.stopCallCount >= 1)
    }
}
