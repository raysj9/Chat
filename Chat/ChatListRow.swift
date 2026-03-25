//
//  ChatListRow.swift
//  Chat
//

import SwiftUI
#if canImport(FoundationModels)

@available(iOS 26.0, macOS 26.0, *)
struct ChatListRow: View {
    let chat: ChatThread

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(chat.title)
                .font(.headline)
                .lineLimit(1)

            Text(chat.preview)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}
#endif
