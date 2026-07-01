//
//  CardView.swift
//  MrHyakuninIsshu
//

import SwiftUI

struct CardView: View {
    let card: Card
    var backgroundColor: Color = Color(.secondarySystemBackground)

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(card.number)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(card.upperText)
                .font(.footnote)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    CardView(card: Card(number: 1, upperPhraseID: "poem_1_upper", lowerPhraseID: "poem_1_lower"))
        .padding()
}
