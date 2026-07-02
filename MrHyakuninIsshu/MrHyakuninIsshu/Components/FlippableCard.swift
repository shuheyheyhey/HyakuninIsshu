//
//  FlippableCard.swift
//  MrHyakuninIsshu
//

import SwiftUI

/// Displays `front` or `back` and animates a 180° flip whenever `isFlipped` changes.
/// Mirrors the rotation mechanics in `CardPreviewView`, but is driven programmatically
/// (no tap gesture) so it can be used for auto-advancing playback.
struct FlippableCard<Front: View, Back: View>: View {
    var isFlipped: Bool
    @ViewBuilder var front: () -> Front
    @ViewBuilder var back: () -> Back

    @State private var rotation: Double = 0

    private var isShowingBack: Bool {
        let normalized = (rotation.truncatingRemainder(dividingBy: 360) + 360)
            .truncatingRemainder(dividingBy: 360)
        return normalized > 90 && normalized < 270
    }

    var body: some View {
        Group {
            if isShowingBack {
                back()
            } else {
                front()
            }
        }
        .rotation3DEffect(.degrees(isShowingBack ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
        .onChange(of: isFlipped) { _, _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                rotation += 180
            }
        }
    }
}
