//
//  TypingIndicatorView.swift
//  Chat
//

import SwiftUI
#if canImport(FoundationModels)

struct TypingIndicatorView: View {
    var body: some View {
        TimelineView(.animation) { context in
            let date = context.date.timeIntervalSinceReferenceDate

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    let phase = date - (Double(index) * 0.18)
                    let opacity = 0.35 + (max(0, sin(phase * 4)) * 0.45)
                    let scale = 0.88 + (max(0, sin(phase * 4)) * 0.24)

                    Circle()
                        .fill(.secondary)
                        .frame(width: 7, height: 7)
                        .opacity(opacity)
                        .scaleEffect(scale)
                }
            }
            .frame(height: 22, alignment: .center)
            .accessibilityLabel("Assistant is typing")
        }
    }
}
#endif
