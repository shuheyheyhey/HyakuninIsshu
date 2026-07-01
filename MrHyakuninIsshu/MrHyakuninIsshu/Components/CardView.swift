//
//  CardView.swift
//  MrHyakuninIsshu
//

import SwiftUI

struct CardView: View {
    let card: Card
    var isSelected: Bool = false
    var backgroundColor: Color = Color(.secondarySystemBackground)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(card.number)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(card.upperText)
                .font(.footnote)
            Text(card.lowerText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.accentColor, lineWidth: 2)
            }
        }
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.accentColor)
                    .padding(6)
            }
        }
    }
}

#Preview {
    HStack {
        CardView(card: Card(number: 1, upperPhraseID: "poem_1_upper", lowerPhraseID: "poem_1_lower"))
        CardView(card: Card(number: 2, upperPhraseID: "poem_2_upper", lowerPhraseID: "poem_2_lower"), isSelected: true)
    }
    .padding()
}
