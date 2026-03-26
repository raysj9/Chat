//
//  ChatListRow.swift
//  Chat
//

import SwiftUI
#if canImport(FoundationModels)

struct ChatListRow: View {
    let chat: ChatThread

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(chat.title)
                    .font(.headline)
                    .lineLimit(1)

                if chat.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(chat.preview)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}
#endif
