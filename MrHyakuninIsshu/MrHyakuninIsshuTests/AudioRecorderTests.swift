//
//  AudioRecorderTests.swift
//  MrHyakuninIsshuTests
//

import Testing
import Foundation
@testable import MrHyakuninIsshu

struct AudioRecorderTests {

    @Test func audioURLPointsToDocumentsAudioDirectory() {
        let url = AudioRecorder.audioURL(for: "poem_1_upper")
        #expect(url.lastPathComponent == "poem_1_upper.m4a")
        #expect(url.deletingLastPathComponent().lastPathComponent == "Audio")
    }

    @Test func hasRecordingReflectsFileExistence() throws {
        let phraseID = "test_\(UUID().uuidString)"
        let url = AudioRecorder.audioURL(for: phraseID)
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(AudioRecorder.hasRecording(for: phraseID) == false)

        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        FileManager.default.createFile(atPath: url.path, contents: Data())

        #expect(AudioRecorder.hasRecording(for: phraseID) == true)
    }
}
