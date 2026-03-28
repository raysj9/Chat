//
//  ChatThread.swift
//  Chat
//

import Foundation
import SwiftData
#if canImport(FoundationModels)

@Model
final class ChatThread {
    enum TitleSource: String, Codable {
        case placeholder
        case generated
        case manual
    }

    var id: UUID = Foundation.UUID()
    var title: String = "New Chat"
    var titleSource: TitleSource = ChatThread.TitleSource.placeholder
    var isPinned: Bool = false
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.thread) var messages: [ChatMessage]?
    var updatedAt: Date = Foundation.Date()

    init(
        id: UUID = UUID(),
        title: String = "New Chat",
        titleSource: TitleSource = .placeholder,
        isPinned: Bool = false,
        messages: [ChatMessage]? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.titleSource = titleSource
        self.isPinned = isPinned
        self.messages = []
        self.updatedAt = updatedAt

        let seededMessages = messages ?? [ChatMessage(role: .assistant, text: "Hi. Send a message to get started.")]
        self.messages = seededMessages

        for message in seededMessages {
            message.thread = self
        }
    }

    var sortedMessages: [ChatMessage] {
        Array(messages ?? []).sorted(by: { lhs, rhs in
            lhs.createdAt < rhs.createdAt
        })
    }

    var preview: String {
        if let lastMeaningful = sortedMessages.last(where: { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            return lastMeaningful.text
        }

        return "No messages yet"
    }
}
#endif
