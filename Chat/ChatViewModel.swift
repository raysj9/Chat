//
//  ChatViewModel.swift
//  Chat
//

import Foundation
import Observation
#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
@Observable
@MainActor
final class ChatViewModel {
    var chats: [ChatThread] = []
    var selectedChatID: ChatThread.ID?
    var errorMessage: String?
    var isSending = false

    private let model = SystemLanguageModel.default
    private let store = ChatStore()
    private var sessions: [ChatThread.ID: LanguageModelSession] = [:]

    init() {
        Task {
            await loadChats()
        }
    }

    var canPromptModel: Bool {
        model.isAvailable
    }

    var selectedChat: ChatThread? {
        guard let selectedChatID else { return nil }
        return chats.first(where: { $0.id == selectedChatID })
    }

    var messages: [ChatMessage] {
        selectedChat?.messages ?? []
    }

    func createChat() {
        let chat = ChatThread()
        chats.insert(chat, at: 0)
        selectedChatID = chat.id
        errorMessage = nil
        persistChats()
    }

    func deleteChats(atOffsets offsets: IndexSet) {
        let removedIDs = offsets.map { chats[$0].id }
        chats = chats.enumerated()
            .filter { !offsets.contains($0.offset) }
            .map(\.element)

        for id in removedIDs {
            sessions[id] = nil
        }

        if chats.isEmpty {
            let chat = ChatThread()
            chats = [chat]
            selectedChatID = chat.id
        } else if removedIDs.contains(selectedChatID ?? UUID()) {
            selectedChatID = chats.first?.id
        }

        errorMessage = nil
        persistChats()
    }

    func renameSelectedChat(to title: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        guard let selectedChatID else { return }
        guard let index = chats.firstIndex(where: { $0.id == selectedChatID }) else { return }

        chats[index].title = trimmedTitle
        chats[index].updatedAt = .now
        persistChats()
    }

    func deleteSelectedChat() {
        guard let selectedChatID else { return }
        guard let index = chats.firstIndex(where: { $0.id == selectedChatID }) else { return }
        deleteChats(atOffsets: IndexSet(integer: index))
    }

    func send(_ prompt: String) async {
        guard canPromptModel else {
            errorMessage = unavailableMessage
            return
        }

        if chats.isEmpty {
            createChat()
        }

        guard let chatID = selectedChatID else { return }

        errorMessage = nil
        isSending = true
        appendMessage(ChatMessage(role: .user, text: prompt), to: chatID)
        updateChatTitleIfNeeded(for: chatID, using: prompt)
        let assistantMessageID = appendAssistantPlaceholder(to: chatID)
        persistChats()

        do {
            let stream = session(for: chatID).streamResponse(to: prompt)
            var streamedText = ""

            for try await snapshot in stream {
                streamedText = snapshot.content
                updateMessage(chatID: chatID, id: assistantMessageID, text: streamedText)
            }

            if streamedText.isEmpty {
                updateMessage(chatID: chatID, id: assistantMessageID, text: "Sorry, I couldn't generate a reply.")
            }
            touchChat(chatID)
            persistChats()
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            removeMessage(chatID: chatID, id: assistantMessageID)
            sessions[chatID] = makeSession(for: messages(in: chatID))
            errorMessage = "That chat got a little too long, so I started a fresh one."
        } catch LanguageModelSession.GenerationError.unsupportedLanguageOrLocale {
            removeMessage(chatID: chatID, id: assistantMessageID)
            errorMessage = "That language isn't supported on this device yet."
        } catch LanguageModelSession.GenerationError.refusal {
            removeMessage(chatID: chatID, id: assistantMessageID)
            errorMessage = "I can't help with that request."
        } catch {
            removeMessage(chatID: chatID, id: assistantMessageID)
            errorMessage = error.localizedDescription
        }

        touchChat(chatID)
        persistChats()
        isSending = false
    }

    private var unavailableMessage: String {
        switch model.availability {
        case .available:
            return ""
        case .unavailable(.deviceNotEligible):
            return "This device can't use chat right now."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Turn on the required device features in Settings, then try again."
        case .unavailable(.modelNotReady):
            return "Getting things ready. Try again in a moment."
        case .unavailable:
            return "Chat isn't available right now."
        }
    }

    private func loadChats() async {
        let savedChats = await store.loadChats()

        if savedChats.isEmpty {
            let chat = ChatThread()
            chats = [chat]
            selectedChatID = chat.id
            persistChats()
        } else {
            chats = savedChats.sorted { $0.updatedAt > $1.updatedAt }
            selectedChatID = chats.first?.id
        }
    }

    private func persistChats() {
        let chatsToSave = chats
        Task {
            await store.saveChats(chatsToSave)
        }
    }

    private func session(for chatID: ChatThread.ID) -> LanguageModelSession {
        if let session = sessions[chatID] {
            return session
        }

        let newSession = makeSession(for: messages(in: chatID))
        sessions[chatID] = newSession
        return newSession
    }

    private func makeSession(for messages: [ChatMessage]) -> LanguageModelSession {
        let transcript = makeTranscript(from: messages)

        if transcript.isEmpty {
            return LanguageModelSession(model: model, instructions: instructionsText)
        }

        return LanguageModelSession(model: model, transcript: transcript)
    }

    private func makeTranscript(from messages: [ChatMessage]) -> Transcript {
        var entries: [Transcript.Entry] = [
            .instructions(
                Transcript.Instructions(
                    segments: [.text(Transcript.TextSegment(content: instructionsText))]
                    ,
                    toolDefinitions: []
                )
            )
        ]

        var hasSeenUserPrompt = false

        for message in messages {
            let text = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }

            let segment = Transcript.Segment.text(Transcript.TextSegment(content: text))

            switch message.role {
            case .user:
                hasSeenUserPrompt = true
                entries.append(.prompt(Transcript.Prompt(segments: [segment])))
            case .assistant:
                guard hasSeenUserPrompt else { continue }
                entries.append(.response(Transcript.Response(assetIDs: [], segments: [segment])))
            }
        }

        return Transcript(entries: entries)
    }

    private var instructionsText: String {
        """
        You are a concise, helpful assistant in a chat app.
        Answer clearly and directly.
        If the request needs nuance, keep the response readable and structured.
        """
    }

    private func appendAssistantPlaceholder(to chatID: ChatThread.ID) -> ChatMessage.ID {
        let message = ChatMessage(role: .assistant, text: "")
        appendMessage(message, to: chatID)
        return message.id
    }

    private func appendMessage(_ message: ChatMessage, to chatID: ChatThread.ID) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[index].messages.append(message)
        chats[index].updatedAt = .now
    }

    private func updateMessage(chatID: ChatThread.ID, id: ChatMessage.ID, text: String) {
        guard let chatIndex = chats.firstIndex(where: { $0.id == chatID }) else { return }
        guard let messageIndex = chats[chatIndex].messages.firstIndex(where: { $0.id == id }) else { return }
        chats[chatIndex].messages[messageIndex].text = text
        chats[chatIndex].updatedAt = .now
    }

    private func removeMessage(chatID: ChatThread.ID, id: ChatMessage.ID) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[index].messages.removeAll { $0.id == id }
        chats[index].updatedAt = .now
    }

    private func messages(in chatID: ChatThread.ID) -> [ChatMessage] {
        chats.first(where: { $0.id == chatID })?.messages ?? []
    }

    private func touchChat(_ chatID: ChatThread.ID) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[index].updatedAt = .now

        let chat = chats.remove(at: index)
        chats.insert(chat, at: 0)
        selectedChatID = chat.id
    }

    private func updateChatTitleIfNeeded(for chatID: ChatThread.ID, using prompt: String) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        guard chats[index].title == "New Chat" else { return }

        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = trimmed.count > 36 ? "\(trimmed.prefix(36))…" : trimmed
        chats[index].title = title.isEmpty ? "New Chat" : title
    }
}
#endif
