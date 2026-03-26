//
//  ContentView.swift
//  Chat
//

import SwiftUI
#if canImport(FoundationModels)
import SwiftData
#endif

struct ContentView: View {
    var body: some View {
        #if canImport(FoundationModels)
        FoundationModelChatView()
        #else
        UnsupportedChatView(
            title: "Foundation Models Unavailable",
            message: "This Xcode toolchain does not include the Foundation Models framework."
        )
        #endif
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ChatThread.self, ChatMessage.self], inMemory: true)
}
