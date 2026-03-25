//
//  ChatMessage.swift
//  Chat
//

import Foundation
import SwiftUI
#if canImport(FoundationModels)

@available(iOS 26.0, macOS 26.0, *)
struct ChatMessage: Identifiable, Equatable, Codable {
    var id = UUID()
    let role: Role
    var text: String

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
}
#endif
