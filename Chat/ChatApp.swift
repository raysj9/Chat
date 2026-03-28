//
//  ChatApp.swift
//  Chat
//

import SwiftUI
import SwiftData

@main
struct ChatApp: App {
    private let sharedModelContainer: ModelContainer = {
        let configuration = ModelConfiguration(cloudKitDatabase: .automatic)

        do {
            return try ModelContainer(
                for: ChatThread.self,
                ChatMessage.self,
                configurations: configuration
            )
        } catch {
            fatalError("Failed to create model container: \(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
