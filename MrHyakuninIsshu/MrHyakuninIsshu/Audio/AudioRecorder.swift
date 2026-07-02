//
//  AudioRecorder.swift
//  MrHyakuninIsshu
//

import Foundation
import AVFoundation
import Observation

@Observable
@MainActor
final class AudioRecorder: NSObject {
    private(set) var isRecording = false
    private(set) var recordingPhraseID: String?

    private var recorder: AVAudioRecorder?

    static let maxDuration: TimeInterval = 15.0

    nonisolated static func audioURL(for phraseID: String) -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents
            .appendingPathComponent("Audio", isDirectory: true)
            .appendingPathComponent("\(phraseID).m4a")
    }

    nonisolated static func hasRecording(for phraseID: String, fileManager: FileManager = .default) -> Bool {
        fileManager.fileExists(atPath: audioURL(for: phraseID).path)
    }

    nonisolated static func deleteRecording(for phraseID: String, fileManager: FileManager = .default) {
        try? fileManager.removeItem(at: audioURL(for: phraseID))
    }

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startRecording(phraseID: String) async {
        guard await requestPermission() else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            return
        }

        let url = Self.audioURL(for: phraseID)
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let newRecorder = try AVAudioRecorder(url: url, settings: settings)
            newRecorder.delegate = self
            newRecorder.record(forDuration: Self.maxDuration)
            recorder = newRecorder
            recordingPhraseID = phraseID
            isRecording = true
        } catch {
            isRecording = false
            recordingPhraseID = nil
        }
    }

    func stopRecording() {
        recorder?.stop()
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            self.isRecording = false
            self.recordingPhraseID = nil
            self.recorder = nil
        }
    }
}
