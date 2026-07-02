//
//  SpeechServiceTests.swift
//  MrHyakuninIsshuTests
//

import Testing
import Foundation
@testable import MrHyakuninIsshu

struct SpeechServiceTests {

    @Test func usesSynthesizedSpeechWhenNoRecordingExists() {
        let phraseID = "test_\(UUID().uuidString)"
        #expect(SpeechService.playbackSource(for: phraseID) == .synthesizedSpeech)
    }

    @Test func usesRecordingWhenFileExists() throws {
        let phraseID = "test_\(UUID().uuidString)"
        let url = AudioRecorder.audioURL(for: phraseID)
        defer { try? FileManager.default.removeItem(at: url) }

        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        FileManager.default.createFile(atPath: url.path, contents: Data())

        #expect(SpeechService.playbackSource(for: phraseID) == .recording)
    }
}

// Note: `SpeechService.playAsync`'s interrupted/finished continuation behavior is exercised
// indirectly via `PlaySessionModelTests`' `FakeSpeechService`, which avoids driving real
// AVSpeechSynthesizer/AVAudioSession playback in a unit test (slow and environment-dependent).
