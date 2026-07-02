//
//  SpeechService.swift
//  MrHyakuninIsshu
//

import Foundation
import AVFoundation
import Observation

@Observable
@MainActor
final class SpeechService: NSObject {
    enum PlaybackSource: Equatable {
        case recording
        case synthesizedSpeech
    }

    enum PlaybackOutcome {
        case finished
        case interrupted
    }

    private(set) var isPlaying = false

    private var audioPlayer: AVAudioPlayer?
    private var synthesizer = AVSpeechSynthesizer()
    private var completion: CheckedContinuation<PlaybackOutcome, Never>?

    nonisolated static func playbackSource(for phraseID: String, fileManager: FileManager = .default) -> PlaybackSource {
        AudioRecorder.hasRecording(for: phraseID, fileManager: fileManager) ? .recording : .synthesizedSpeech
    }

    func play(phraseID: String, readingText: String) {
        beginPlayback(phraseID: phraseID, readingText: readingText)
    }

    /// Plays the phrase and suspends until playback finishes naturally or is interrupted by `stop()`.
    func playAsync(phraseID: String, readingText: String) async -> PlaybackOutcome {
        resumeCompletion(with: .interrupted)
        return await withCheckedContinuation { continuation in
            self.completion = continuation
            beginPlayback(phraseID: phraseID, readingText: readingText)
        }
    }

    private func beginPlayback(phraseID: String, readingText: String) {
        switch Self.playbackSource(for: phraseID) {
        case .recording:
            playRecording(at: AudioRecorder.audioURL(for: phraseID))
        case .synthesizedSpeech:
            speak(readingText)
        }
    }

    private func playRecording(at url: URL) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            isPlaying = true
            player.play()
            audioPlayer = player
        } catch {
            isPlaying = false
        }
    }

    private func speak(_ text: String) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            // Proceed regardless — the synthesizer may still play using whatever
            // session state is already active.
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        synthesizer.delegate = self
        isPlaying = true
        synthesizer.speak(utterance)
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            // AVSpeechSynthesizer can end up in a confused state (delegate callbacks silently
            // stop firing, or fire prematurely) if a new utterance is handed to it immediately
            // after being force-stopped — which happens whenever skip/pause interrupt a reading.
            // A fresh instance for the next utterance avoids relying on that undocumented timing.
            synthesizer = AVSpeechSynthesizer()
        }
        isPlaying = false
        resumeCompletion(with: .interrupted)
    }

    private func finishedNaturally() {
        isPlaying = false
        resumeCompletion(with: .finished)
    }

    private func resumeCompletion(with outcome: PlaybackOutcome) {
        guard let completion else { return }
        self.completion = nil
        completion.resume(returning: outcome)
    }
}

extension SpeechService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.finishedNaturally()
        }
    }
}

extension SpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.finishedNaturally()
        }
    }
}

@MainActor
protocol SpeechServicing: AnyObject {
    func playAsync(phraseID: String, readingText: String) async -> SpeechService.PlaybackOutcome
    func stop()
}

extension SpeechService: SpeechServicing {}
