//
//  MessageBubble.swift
//  Chat
//

import SwiftUI
#if canImport(FoundationModels)

struct MessageBubble: View {
    let message: ChatMessage

    private var isShowingTypingIndicator: Bool {
        message.role == .assistant && message.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack {
            if message.role == .assistant {
                bubble
                Spacer(minLength: 48)
            } else {
                Spacer(minLength: 48)
                bubble
            }
        }
        .padding(.vertical, 2)
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(message.role.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(message.role.tint)

            if isShowingTypingIndicator {
                TypingIndicatorView()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(message.text)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(
            message.role.glass,
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
    }
}
#endif
