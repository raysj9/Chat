//
//  ChatMessage.swift
//  Chat
//

import Foundation
import SwiftData
import SwiftUI
#if canImport(FoundationModels)

@Model
final class ChatMessage {
    enum Role: String, Equatable, Codable {
        case user
        case assistant

        var label: String {
            switch self {
            case .user:
                return "You"
            case .assistant:
                return "Assistant"
            }
        }

        var tint: Color {
            switch self {
            case .user:
                return .white
            case .assistant:
                return .primary
            }
        }

        var bubbleBackground: Color {
            switch self {
            case .user:
                return .blue
            case .assistant:
                return Color(.secondarySystemFill)
            }
        }
    }

    var id: UUID = Foundation.UUID()
    var role: Role = ChatMessage.Role.assistant
    var text: String = ""
    var createdAt: Date = Foundation.Date()
    var thread: ChatThread?

    init(
        id: UUID = UUID(),
        role: Role,
        text: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
        self.thread = nil
    }
}
#endif
