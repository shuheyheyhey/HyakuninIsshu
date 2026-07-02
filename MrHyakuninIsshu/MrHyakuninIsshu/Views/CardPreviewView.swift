//
//  CardPreviewView.swift
//  MrHyakuninIsshu
//

import SwiftUI

struct CardPreviewView: View {
    let card: Card

    var body: some View {
        VStack(spacing: 16) {
            Text(card.upperText)
                .font(.title3)
            Text(card.lowerText)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("第\(card.number)首")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CardPreviewView(card: Card(number: 1, upperPhraseID: "poem_1_upper", lowerPhraseID: "poem_1_lower"))
    }
}
