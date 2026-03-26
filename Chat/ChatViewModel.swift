//
//  ChatViewModel.swift
//  Chat
//

import Foundation
import Observation
#if canImport(FoundationModels)
import FoundationModels
import SwiftData

@Observable
@MainActor
final class ChatViewModel {
    var chats: [ChatThread] = []
    var selectedChatID: UUID?
    var searchText = ""
    var errorMessage: String?
    var isSending = false

    private let model = SystemLanguageModel.default
    private var modelContext: ModelContext?
    private var hasConfiguredPersistence = false
    private var sessions: [UUID: LanguageModelSession] = [:]

    func configureIfNeeded(modelContext: ModelContext) async {
        guard !hasConfiguredPersistence else { return }

        self.modelContext = modelContext
        hasConfiguredPersistence = true
        await loadChats()
    }

    var canPromptModel: Bool {
        model.isAvailable
    }

    var selectedChat: ChatThread? {
        guard let selectedChatID else { return nil }
        return chats.first(where: { $0.id == selectedChatID })
    }

    var messages: [ChatMessage] {
        selectedChat?.sortedMessages ?? []
    }

    var filteredChats: [ChatThread] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sortedChats(chats) }

        return sortedChats(chats.filter { chat in
            chat.title.localizedCaseInsensitiveContains(query)
                || chat.sortedMessages.contains { $0.text.localizedCaseInsensitiveContains(query) }
        })
    }

    func createChat() {
        guard let modelContext else { return }

        let chat = ChatThread()
        modelContext.insert(chat)
        chats.append(chat)
        selectedChatID = chat.id
        errorMessage = nil
        sortChatsInPlace()
        saveChanges()
    }

    func deleteChats(atOffsets offsets: IndexSet) {
        let ids = offsets.map { chats[$0].id }
        deleteChats(withIDs: ids)
    }

    func renameSelectedChat(to title: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        guard let selectedChatID else { return }
        guard let index = chats.firstIndex(where: { $0.id == selectedChatID }) else { return }

        chats[index].title = trimmedTitle
        chats[index].titleSource = .manual
        chats[index].updatedAt = .now
        sortChatsInPlace()
        saveChanges()
    }

    func deleteSelectedChat() {
        guard let selectedChatID else { return }
        guard let index = chats.firstIndex(where: { $0.id == selectedChatID }) else { return }
        deleteChats(atOffsets: IndexSet(integer: index))
    }

    func togglePinForSelectedChat() {
        guard let selectedChatID else { return }
        togglePin(for: selectedChatID)
    }

    func togglePin(for chatID: ChatThread.ID) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }

        chats[index].isPinned.toggle()
        chats[index].updatedAt = .now
        sortChatsInPlace()
        saveChanges()
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
        let assistantMessageID = appendAssistantPlaceholder(to: chatID)
        saveChanges()

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
            await generateSuggestedTitleIfNeeded(for: chatID)
            touchChat(chatID)
            saveChanges()
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
        saveChanges()
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
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<ChatThread>()
        let savedChats = (try? modelContext.fetch(descriptor)) ?? []

        if savedChats.isEmpty {
            let chat = ChatThread()
            modelContext.insert(chat)
            chats = [chat]
            selectedChatID = chat.id
            saveChanges()
        } else {
            chats = sortedChats(savedChats)
            selectedChatID = chats.first?.id
        }
    }

    private func saveChanges() {
        guard let modelContext, modelContext.hasChanges else { return }

        do {
            try modelContext.save()
        } catch {
            errorMessage = "Your chats couldn't be saved right now."
        }
    }

    private func session(for chatID: UUID) -> LanguageModelSession {
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

    private func appendAssistantPlaceholder(to chatID: UUID) -> UUID {
        let message = ChatMessage(role: .assistant, text: "")
        appendMessage(message, to: chatID)
        return message.id
    }

    private func appendMessage(_ message: ChatMessage, to chatID: UUID) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        modelContext?.insert(message)
        chats[index].messages.append(message)
        chats[index].updatedAt = .now
    }

    private func updateMessage(chatID: UUID, id: UUID, text: String) {
        guard let chatIndex = chats.firstIndex(where: { $0.id == chatID }) else { return }
        guard let messageIndex = chats[chatIndex].messages.firstIndex(where: { $0.id == id }) else { return }
        chats[chatIndex].messages[messageIndex].text = text
        chats[chatIndex].updatedAt = .now
    }

    private func removeMessage(chatID: UUID, id: UUID) {
        guard let modelContext else { return }
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        guard let messageIndex = chats[index].messages.firstIndex(where: { $0.id == id }) else { return }

        let message = chats[index].messages.remove(at: messageIndex)
        modelContext.delete(message)
        chats[index].updatedAt = .now
    }

    private func messages(in chatID: UUID) -> [ChatMessage] {
        chats.first(where: { $0.id == chatID })?.sortedMessages ?? []
    }

    private func touchChat(_ chatID: UUID) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[index].updatedAt = .now
        sortChatsInPlace()
        selectedChatID = chatID
    }

    private func deleteChats(withIDs ids: [UUID]) {
        guard let modelContext else { return }

        let deletedChats = chats.filter { ids.contains($0.id) }
        chats.removeAll { ids.contains($0.id) }

        for id in ids {
            sessions[id] = nil
        }

        for chat in deletedChats {
            modelContext.delete(chat)
        }

        if chats.isEmpty {
            let chat = ChatThread()
            modelContext.insert(chat)
            chats = [chat]
            selectedChatID = chat.id
        } else if let currentSelectedChatID = selectedChatID, ids.contains(currentSelectedChatID) {
            selectedChatID = chats.first?.id
        }

        errorMessage = nil
        sortChatsInPlace()
        saveChanges()
    }

    private func generateSuggestedTitleIfNeeded(for chatID: UUID) async {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        guard chats[index].titleSource == .placeholder else { return }

        let userMessages = chats[index].sortedMessages.filter {
            $0.role == .user && !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard userMessages.count == 1 else { return }

        let titleSession = LanguageModelSession(
            model: model,
            instructions: """
            Generate a short chat title that summarizes the user's request.
            Use 2 to 5 words.
            Do not answer the request.
            Do not expand beyond the user's wording.
            Prefer a topic label or paraphrase over a response.
            Do not use quotes, bullets, or markdown.
            Return only the title text.
            """
        )

        do {
            let response = try await titleSession.respond(
                to: """
                Summarize this user message as a chat title without answering it:
                \(userMessages[0].text)
                """
            )

            let suggestedTitle = sanitizeSuggestedTitle(response.content)
            guard !suggestedTitle.isEmpty else { return }
            guard let refreshedIndex = chats.firstIndex(where: { $0.id == chatID }) else { return }
            guard chats[refreshedIndex].titleSource == .placeholder else { return }

            chats[refreshedIndex].title = suggestedTitle
            chats[refreshedIndex].titleSource = .generated
            saveChanges()
        } catch {
            // Keep the existing title when generation fails.
        }
    }

    private func sanitizeSuggestedTitle(_ rawTitle: String) -> String {
        let trimmed = rawTitle
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'“”‘’`.,:;!-"))

        let collapsed = trimmed.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )

        if collapsed.count > 40 {
            return String(collapsed.prefix(40)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return collapsed
    }

    private func sortChatsInPlace() {
        chats = sortedChats(chats)
    }

    private func sortedChats(_ chats: [ChatThread]) -> [ChatThread] {
        chats.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }

            return lhs.updatedAt > rhs.updatedAt
        }
    }
}
#endif
