//
//  ChatThread.swift
//  Chat
//

import Foundation
#if canImport(FoundationModels)

@available(iOS 26.0, macOS 26.0, *)
struct ChatThread: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "New Chat",
        messages: [ChatMessage] = [ChatMessage(role: .assistant, text: "Hi. Send a message to get started.")],
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.updatedAt = updatedAt
    }

    var preview: String {
        if let lastMeaningful = messages.last(where: { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            return lastMeaningful.text
        }

        return "No messages yet"
    }
}
#endif
