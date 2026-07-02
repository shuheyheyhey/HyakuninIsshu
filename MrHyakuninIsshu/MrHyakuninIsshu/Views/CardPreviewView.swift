//
//  CardPreviewView.swift
//  MrHyakuninIsshu
//

import SwiftUI

struct CardPreviewView: View {
    let card: Card
    let borderColorHex: String

    @State private var rotation: Double = 0
    @State private var audioRecorder = AudioRecorder()
    @State private var speechService = SpeechService()
    @State private var showsOverwriteConfirmation = false

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

    var body: some View {
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
                    withAnimation(.easeInOut(duration: 0.5)) {
                        rotation += 180
                    }
                }

            Spacer()

            HStack(spacing: 48) {
                Button {
                    handleRecordTap()
                } label: {
                    Image(systemName: audioRecorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(audioRecorder.isRecording ? .red : .accentColor)
                }

                Button {
                    speechService.play(phraseID: currentPhraseID, readingText: currentReading)
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 48))
                }
                .disabled(speechService.isPlaying)
            }
            .padding(.bottom, 40)
        }
        .padding()
        .alert("上書きして再録音しますか？", isPresented: $showsOverwriteConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("再録音", role: .destructive) {
                Task {
                    await audioRecorder.startRecording(phraseID: currentPhraseID)
                }
            }
        }
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
