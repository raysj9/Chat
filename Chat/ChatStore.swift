//
//  ChatStore.swift
//  Chat
//

import Foundation
#if canImport(FoundationModels)

@available(iOS 26.0, macOS 26.0, *)
actor ChatStore {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func loadChats() -> [ChatThread] {
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([ChatThread].self, from: data)
        } catch {
            return []
        }
    }

    func saveChats(_ chats: [ChatThread]) {
        do {
            let data = try encoder.encode(chats)
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            assertionFailure("Failed to save chats: \(error)")
        }
    }

    private var directoryURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Chat", isDirectory: true)
    }

    private var fileURL: URL {
        directoryURL.appendingPathComponent("threads.json")
    }
}
#endif
