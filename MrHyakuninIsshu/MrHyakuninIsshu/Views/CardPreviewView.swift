//
//  CardPreviewView.swift
//  MrHyakuninIsshu
//

import SwiftUI

struct CardPreviewView: View {
    let card: Card
    let borderColorHex: String

    @Environment(\.dismiss) private var dismiss

    @State private var rotation: Double = 0
    @State private var audioRecorder = AudioRecorder()
    @State private var speechService = SpeechService()
    @State private var showsOverwriteConfirmation = false
    @State private var showsDeleteConfirmation = false
    @State private var recordingRefreshTrigger = 0

    private var isBackFace: Bool {
        let normalized = (rotation.truncatingRemainder(dividingBy: 360) + 360)
            .truncatingRemainder(dividingBy: 360)
        return normalized > 90 && normalized < 270
    }

    private var currentPhraseID: String {
        isBackFace ? card.lowerPhraseID : card.upperPhraseID
    }

    private var currentReading: String {
        isBackFace ? card.lowerReading : card.upperReading
    }

    private var hasCurrentRecording: Bool {
        _ = recordingRefreshTrigger
        return AudioRecorder.hasRecording(for: currentPhraseID)
    }

    private var isBusy: Bool {
        audioRecorder.isRecording || speechService.isPlaying
    }

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    handleBackgroundTap()
                }

            VStack(spacing: 32) {
                Spacer()

                cardFace(
                    label: isBackFace ? "下の句" : "上の句",
                    text: isBackFace ? card.lowerText : card.upperText,
                    reading: isBackFace ? card.lowerReading : card.upperReading
                )
                    .rotation3DEffect(.degrees(isBackFace ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                    .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
                    .onTapGesture {
                        guard !isBusy else { return }
                        withAnimation(.easeInOut(duration: 0.5)) {
                            rotation += 180
                        }
                    }

                Spacer()

                VStack(spacing: 16) {
                    HStack(spacing: 48) {
                        Button {
                            handleRecordTap()
                        } label: {
                            Image(systemName: audioRecorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.red)
                        }
                        .disabled(speechService.isPlaying)

                        Button {
                            handlePlayTap()
                        } label: {
                            Image(systemName: speechService.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(speechService.isPlaying ? .red : .accentColor)
                        }
                        .disabled(audioRecorder.isRecording)
                    }

                    Button(role: .destructive) {
                        showsDeleteConfirmation = true
                    } label: {
                        Label("録音を削除", systemImage: "trash")
                    }
                    .disabled(!hasCurrentRecording || isBusy)
                }
                .padding(.bottom, 40)
            }
            .padding()
        }
        .interactiveDismissDisabled(isBusy)
        .onChange(of: audioRecorder.isRecording) { _, isRecording in
            if !isRecording {
                recordingRefreshTrigger += 1
            }
        }
        .alert("上書きして再録音しますか？", isPresented: $showsOverwriteConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("再録音", role: .destructive) {
                Task {
                    await audioRecorder.startRecording(phraseID: currentPhraseID)
                }
            }
        }
        .alert("録音を削除しますか？", isPresented: $showsDeleteConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                AudioRecorder.deleteRecording(for: currentPhraseID)
                recordingRefreshTrigger += 1
            }
        }
    }

    private func handleBackgroundTap() {
        guard isBusy else { return }
        audioRecorder.stopRecording()
        speechService.stop()
        dismiss()
    }

    private func handleRecordTap() {
        if audioRecorder.isRecording {
            audioRecorder.stopRecording()
            return
        }
        if AudioRecorder.hasRecording(for: currentPhraseID) {
            showsOverwriteConfirmation = true
        } else {
            Task {
                await audioRecorder.startRecording(phraseID: currentPhraseID)
            }
        }
    }

    private func handlePlayTap() {
        if speechService.isPlaying {
            speechService.stop()
        } else {
            speechService.play(phraseID: currentPhraseID, readingText: currentReading)
        }
    }

    private func cardFace(label: String, text: String, reading: String) -> some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color(hex: borderColorHex), lineWidth: 6)
            )
            .overlay(alignment: .topLeading) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(16)
            }
            .overlay {
                VStack(spacing: 16) {
                    Text(text)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                    Text(reading)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
            }
            .frame(height: 340)
            .padding(.horizontal, 24)
            .shadow(radius: 8)
    }
}

#Preview {
    CardPreviewView(
        card: Card(number: 1, upperPhraseID: "poem_1_upper", lowerPhraseID: "poem_1_lower"),
        borderColorHex: "#4A90D9"
    )
}
