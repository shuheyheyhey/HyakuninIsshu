//
//  PlaySessionModel.swift
//  MrHyakuninIsshu
//

import Foundation
import Observation

@Observable
@MainActor
final class PlaySessionModel {
    enum Phase: Equatable {
        case notStarted
        case playingUpper
        case upperToLowerInterval
        case playingLower
        case interCardInterval
        case completed
    }

    /// Outcome of a single awaited step (a phrase read or an interval wait). Delivered directly
    /// through the step's continuation at the moment `pause()`/`skip()` is called, rather than
    /// being re-derived afterwards from a separately mutated flag — the latter is racy when
    /// `pause()` and `resume()` are called back-to-back with no suspension in between, since the
    /// halted step would then observe the flag's *new* value instead of the one that was true
    /// when it was actually paused.
    private enum StepOutcome {
        case finished
        case skipped
        case paused
    }

    private(set) var phase: Phase = .notStarted
    private(set) var currentIndex: Int = 0
    private(set) var queue: [Card] = []
    private(set) var isPaused: Bool = false

    var currentCard: Card? {
        queue.indices.contains(currentIndex) ? queue[currentIndex] : nil
    }

    /// True once the lower phrase's phase begins, so views can drive a flip from this value.
    var isShowingBack: Bool {
        phase == .playingLower || phase == .interCardInterval
    }

    var isFinished: Bool {
        phase == .completed
    }

    private let speechService: any SpeechServicing
    private let shuffle: ([Card]) -> [Card]
    private let intervalSleep: (TimeInterval) async -> Void

    private var runTask: Task<Void, Never>?
    private var stepContinuation: CheckedContinuation<StepOutcome, Never>?
    private var backgroundTask: Task<Void, Never>?

    init(
        speechService: (any SpeechServicing)? = nil,
        shuffle: @escaping ([Card]) -> [Card] = { $0.shuffled() },
        intervalSleep: @escaping (TimeInterval) async -> Void = { seconds in
            try? await Task.sleep(for: .seconds(seconds))
        }
    ) {
        self.speechService = speechService ?? SpeechService()
        self.shuffle = shuffle
        self.intervalSleep = intervalSleep
    }

    // MARK: Public API

    func start(cards: [Card], upperToLowerInterval: TimeInterval, interCardInterval: TimeInterval) {
        runTask?.cancel()
        queue = shuffle(cards)
        currentIndex = 0
        phase = .notStarted
        isPaused = false
        runTask = Task { [weak self] in
            await self?.run(upperToLowerInterval: upperToLowerInterval, interCardInterval: interCardInterval)
        }
    }

    func resume(upperToLowerInterval: TimeInterval, interCardInterval: TimeInterval) {
        guard isPaused else { return }
        isPaused = false
        runTask = Task { [weak self] in
            await self?.run(upperToLowerInterval: upperToLowerInterval, interCardInterval: interCardInterval)
        }
    }

    func pause() {
        guard phase != .notStarted, phase != .completed, !isPaused else { return }
        isPaused = true
        speechService.stop()
        completeStep(.paused)
    }

    /// Interrupts the current reading (or interval wait) and proceeds directly to the start of
    /// the next phrase's reading — any interval between them is collapsed rather than played out
    /// silently, since a "skip" is expected to behave like a media player's next-track button.
    func skip() {
        guard phase != .notStarted, phase != .completed, !isPaused else { return }
        speechService.stop()
        completeStep(.skipped)
    }

    func reset() {
        runTask?.cancel()
        runTask = nil
        speechService.stop()
        completeStep(.paused)
        queue = []
        currentIndex = 0
        phase = .notStarted
        isPaused = false
    }

    // MARK: Run loop (re-entrant: picks up wherever `phase` currently is)

    private func run(upperToLowerInterval: TimeInterval, interCardInterval: TimeInterval) async {
        if phase == .notStarted { phase = .playingUpper }
        var bypassNextInterval = false
        while currentIndex < queue.count {
            guard !isPaused else { return }
            let card = queue[currentIndex]

            if phase == .playingUpper {
                switch await awaitPhrase(card.upperPhraseID, card.upperReading) {
                case .paused: return
                case .finished: bypassNextInterval = false
                case .skipped: bypassNextInterval = true
                }
                phase = .upperToLowerInterval
            }
            guard !isPaused else { return }
            if phase == .upperToLowerInterval {
                if bypassNextInterval {
                    bypassNextInterval = false
                } else {
                    guard await awaitInterval(upperToLowerInterval) != .paused else { return }
                }
                phase = .playingLower
            }
            guard !isPaused else { return }
            if phase == .playingLower {
                switch await awaitPhrase(card.lowerPhraseID, card.lowerReading) {
                case .paused: return
                case .finished: bypassNextInterval = false
                case .skipped: bypassNextInterval = true
                }
                phase = .interCardInterval
            }
            guard !isPaused else { return }
            if phase == .interCardInterval {
                if bypassNextInterval {
                    bypassNextInterval = false
                } else {
                    guard await awaitInterval(interCardInterval) != .paused else { return }
                }
                currentIndex += 1
                phase = currentIndex < queue.count ? .playingUpper : .completed
            }
        }
        phase = .completed
    }

    // MARK: Awaited steps

    private func awaitPhrase(_ phraseID: String, _ reading: String) async -> StepOutcome {
        await withCheckedContinuation { continuation in
            stepContinuation = continuation
            backgroundTask = Task { [weak self] in
                guard let self else { return }
                if await self.speechService.playAsync(phraseID: phraseID, readingText: reading) == .finished {
                    self.completeStep(.finished)
                }
                // `.interrupted` means `pause()`/`skip()` already resolved this step directly.
            }
        }
    }

    private func awaitInterval(_ seconds: TimeInterval) async -> StepOutcome {
        guard seconds > 0 else { return .finished }
        return await withCheckedContinuation { continuation in
            stepContinuation = continuation
            backgroundTask = Task { [weak self] in
                guard let self else { return }
                await self.intervalSleep(seconds)
                self.completeStep(.finished)
            }
        }
    }

    private func completeStep(_ outcome: StepOutcome) {
        backgroundTask?.cancel()
        backgroundTask = nil
        guard let continuation = stepContinuation else { return }
        stepContinuation = nil
        continuation.resume(returning: outcome)
    }
}
