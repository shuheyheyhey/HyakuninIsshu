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
    private var backupURL: URL?
    private var shouldDiscardOnFinish = false

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

        // 上書き前の録音があれば、中断時に復元できるようバックアップしておく
        if FileManager.default.fileExists(atPath: url.path) {
            let backup = url.appendingPathExtension("bak")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.moveItem(at: url, to: backup)
            backupURL = backup
        } else {
            backupURL = nil
        }

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
            shouldDiscardOnFinish = false
            isRecording = true
        } catch {
            isRecording = false
            recordingPhraseID = nil
            restoreBackupIfNeeded(discardedURL: url)
        }
    }

    /// ユーザーが明示的に録音を終える（新しい録音を残す）
    func stopRecording() {
        shouldDiscardOnFinish = false
        recorder?.stop()
    }

    /// 録音を中断し、開始前の状態（元の録音がなければ無録音）に戻す
    func cancelRecording() {
        shouldDiscardOnFinish = true
        recorder?.stop()
    }

    private func restoreBackupIfNeeded(discardedURL: URL) {
        try? FileManager.default.removeItem(at: discardedURL)
        if let backupURL {
            try? FileManager.default.moveItem(at: backupURL, to: discardedURL)
        }
        backupURL = nil
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        let url = recorder.url
        Task { @MainActor in
            if self.shouldDiscardOnFinish {
                self.restoreBackupIfNeeded(discardedURL: url)
            } else if let backupURL = self.backupURL {
                try? FileManager.default.removeItem(at: backupURL)
                self.backupURL = nil
            }
            self.shouldDiscardOnFinish = false
            self.isRecording = false
            self.recordingPhraseID = nil
            self.recorder = nil
        }
    }
}
