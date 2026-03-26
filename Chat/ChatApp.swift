//
//  ChatApp.swift
//  Chat
//

import SwiftUI
import SwiftData

@main
struct ChatApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [ChatThread.self, ChatMessage.self])
    }
}
