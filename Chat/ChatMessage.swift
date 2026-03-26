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
                return .blue
            case .assistant:
                return .primary
            }
        }

        var glass: Glass {
            switch self {
            case .user:
                return .regular.tint(.blue.opacity(0.28))
            case .assistant:
                return .regular.tint(.white.opacity(0.16))
            }
        }
    }

    @Attribute(.unique) var id: UUID
    var role: Role
    var text: String
    var createdAt: Date

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
    }
}
#endif
