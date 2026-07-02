//
//  CardPreviewView.swift
//  MrHyakuninIsshu
//

import SwiftUI

struct CardPreviewView: View {
    let card: Card
    let borderColorHex: String

    @State private var rotation: Double = 0

    private var isBackFace: Bool {
        let normalized = (rotation.truncatingRemainder(dividingBy: 360) + 360)
            .truncatingRemainder(dividingBy: 360)
        return normalized > 90 && normalized < 270
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
                    // 録音: UIのみ。機能は後で実装。
                } label: {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 48))
                }

                Button {
                    // 再生: UIのみ。未録音時はTTSで読み上げる想定（後で実装）。
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 48))
                }
            }
            .padding(.bottom, 40)
        }
        .padding()
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
