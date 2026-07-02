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

    private(set) var isPlaying = false

    private var audioPlayer: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()

    nonisolated static func playbackSource(for phraseID: String, fileManager: FileManager = .default) -> PlaybackSource {
        AudioRecorder.hasRecording(for: phraseID, fileManager: fileManager) ? .recording : .synthesizedSpeech
    }

    func play(phraseID: String, readingText: String) {
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
        }
        isPlaying = false
    }
}

extension SpeechService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
        }
    }
}

extension SpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPlaying = false
        }
    }
}
