//
//  PlayView.swift
//  MrHyakuninIsshu
//

import SwiftUI

struct PlayView: View {
    let cards: [Card]
    let borderColorHex: String

    @AppStorage("upperToLowerInterval") private var upperToLowerInterval: Double = 3
    @AppStorage("interCardInterval") private var interCardInterval: Double = 2

    @State private var session = PlaySessionModel()
    @State private var hasStartedPlaying = false
    @State private var showsCloseConfirmation = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if hasStartedPlaying {
                    playbackView
                } else {
                    settingsView
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        handleCloseTapped()
                    }
                }
            }
        }
        .onDisappear {
            session.reset()
        }
        .alert("再生を中断しますか？", isPresented: $showsCloseConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("閉じる", role: .destructive) {
                dismiss()
            }
        }
    }

    private func handleCloseTapped() {
        if hasStartedPlaying && !session.isFinished {
            session.pause()
            showsCloseConfirmation = true
        } else {
            dismiss()
        }
    }

    private var settingsView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                Label("上の句を読んだあと、続けて下の句を読み上げます", systemImage: "text.book.closed")
                Label("カードはランダムな順番で出題されます", systemImage: "shuffle")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            VStack(spacing: 20) {
                intervalRow(title: "上の句読み終わり→下の句読み始め", value: $upperToLowerInterval)
                intervalRow(title: "下の句読み終わり→次の句読み始め", value: $interCardInterval)
            }

            Button("プレイ") {
                hasStartedPlaying = true
                session.start(
                    cards: cards,
                    upperToLowerInterval: upperToLowerInterval,
                    interCardInterval: interCardInterval
                )
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(cards.isEmpty)

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private func intervalRow(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button {
                    value.wrappedValue = max(0, value.wrappedValue - 1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                }
                .disabled(value.wrappedValue <= 0)

                HStack(spacing: 2) {
                    Text("\(Int(value.wrappedValue))")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                    Text("秒")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .frame(minWidth: 56)

                Button {
                    value.wrappedValue = min(30, value.wrappedValue + 1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(value.wrappedValue >= 30)
            }
        }
    }

    private var playbackView: some View {
        VStack(spacing: 32) {
            Spacer()

            if let card = session.currentCard {
                FlippableCard(isFlipped: session.isShowingBack) {
                    cardFace(
                        label: "上の句",
                        text: card.upperText,
                        reading: card.upperReading
                    )
                } back: {
                    cardFace(
                        label: "下の句",
                        text: card.lowerText,
                        reading: card.lowerReading
                    )
                }
            } else if session.isFinished {
                completionView
            }

            Spacer()

            if !session.isFinished {
                HStack(spacing: 48) {
                    Button {
                        if session.isPaused {
                            session.resume(
                                upperToLowerInterval: upperToLowerInterval,
                                interCardInterval: interCardInterval
                            )
                        } else {
                            session.pause()
                        }
                    } label: {
                        Image(systemName: session.isPaused ? "play.circle.fill" : "pause.circle.fill")
                            .font(.system(size: 48))
                    }

                    Button {
                        session.skip()
                    } label: {
                        Image(systemName: "forward.end.circle.fill")
                            .font(.system(size: 48))
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    private var completionView: some View {
        Text("読み終えました")
            .font(.title2)
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
    PlayView(
        cards: [Card(number: 1, upperPhraseID: "poem_1_upper", lowerPhraseID: "poem_1_lower")],
        borderColorHex: "#4A90D9"
    )
}
