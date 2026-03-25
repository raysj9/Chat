//
//  ChatBackgroundView.swift
//  Chat
//

import SwiftUI
#if canImport(FoundationModels)

@available(iOS 26.0, macOS 26.0, *)
struct ChatBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(highlightColor)
                .frame(width: 240, height: 240)
                .blur(radius: 40)
                .offset(x: 60, y: -40)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(accentGlowColor)
                .frame(width: 280, height: 280)
                .blur(radius: 50)
                .offset(x: -80, y: 80)
        }
        .ignoresSafeArea()
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            [
                Color(red: 0.08, green: 0.10, blue: 0.14),
                Color(red: 0.10, green: 0.14, blue: 0.20),
                Color(red: 0.07, green: 0.12, blue: 0.18)
            ]
        } else {
            [
                Color(red: 0.96, green: 0.98, blue: 1.0),
                Color(red: 0.90, green: 0.95, blue: 1.0),
                Color(red: 0.87, green: 0.93, blue: 0.98)
            ]
        }
    }

    private var highlightColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.6)
    }

    private var accentGlowColor: Color {
        colorScheme == .dark ? Color.cyan.opacity(0.10) : Color.cyan.opacity(0.18)
    }
}
#endif
