//
//  FoundationModelChatView.swift
//  Chat
//

import SwiftUI
#if canImport(FoundationModels)
import FoundationModels
import SwiftData

struct FoundationModelChatView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ChatViewModel()
    @State private var draft = ""
    @State private var isShowingRenamePrompt = false
    @State private var isShowingDeleteConfirmation = false
    @State private var renameDraft = ""

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationSplitView {
            List(selection: $viewModel.selectedChatID) {
                ForEach(viewModel.filteredChats) { chat in
                    ChatListRow(chat: chat)
                        .tag(chat.id)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                viewModel.togglePin(for: chat.id)
                            } label: {
                                Label(
                                    chat.isPinned ? "Unpin" : "Pin",
                                    systemImage: chat.isPinned ? "pin.slash" : "pin"
                                )
                            }
                            .tint(chat.isPinned ? .gray : .yellow)
                        }
                }
                .onDelete(perform: deleteFilteredChats)
            }
            .searchable(text: $viewModel.searchText, prompt: "Search chats")
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.createChat()
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        } detail: {
            ZStack(alignment: .bottom) {
                ChatBackgroundView()
                ChatTranscriptView(messages: viewModel.messages)
                ChatComposerView(
                    draft: $draft,
                    canPromptModel: viewModel.canPromptModel,
                    isSending: viewModel.isSending,
                    errorMessage: viewModel.errorMessage,
                    onSubmit: submitDraft
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            .navigationTitle(viewModel.selectedChat?.title ?? "Chat")
            .toolbarTitleDisplayMode(.inline)
            #if !os(macOS)
            .toolbarBackground(.hidden, for: .navigationBar)
            #endif
            .toolbar {
            #if os(macOS)
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        renameDraft = viewModel.selectedChat?.title ?? ""
                        isShowingRenamePrompt = true
                    } label: {
                        Label("Rename Chat", systemImage: "pencil")
                    }
                    .disabled(viewModel.selectedChat == nil)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.togglePinForSelectedChat()
                    } label: {
                        Label(
                            viewModel.selectedChat?.isPinned == true ? "Unpin Chat" : "Pin Chat",
                            systemImage: viewModel.selectedChat?.isPinned == true ? "pin.slash" : "pin"
                        )
                    }
                    .disabled(viewModel.selectedChat == nil)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) {
                        isShowingDeleteConfirmation = true
                    } label: {
                        Label("Delete Chat", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                    .disabled(viewModel.selectedChat == nil)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.createChat()
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            #else
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.createChat()
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    chatActionsMenu
                }
            #endif
            }
            .alert("Rename Chat", isPresented: $isShowingRenamePrompt) {
                TextField("Chat name", text: $renameDraft)

                Button("Save") {
                    viewModel.renameSelectedChat(to: renameDraft)
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose a new name for this chat.")
            }
            .confirmationDialog(
                "Delete this chat?",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Chat", role: .destructive) {
                    viewModel.deleteSelectedChat()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
        }
        .task {
            await viewModel.configureIfNeeded(modelContext: modelContext)
        }
    }

    private func submitDraft() {
        let prompt = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        draft = ""

        Task {
            await viewModel.send(prompt)
        }
    }

    private func deleteFilteredChats(at offsets: IndexSet) {
        let ids = offsets.map { viewModel.filteredChats[$0].id }
        let allOffsets = IndexSet(
            ids.compactMap { id in
                viewModel.chats.firstIndex(where: { $0.id == id })
            }
        )
        viewModel.deleteChats(atOffsets: allOffsets)
    }

    @ViewBuilder
    private var chatActionsMenu: some View {
        if viewModel.selectedChat != nil {
            Menu {
                Button {
                    renameDraft = viewModel.selectedChat?.title ?? ""
                    isShowingRenamePrompt = true
                } label: {
                    Label("Rename Chat", systemImage: "pencil")
                }

                Button {
                    viewModel.togglePinForSelectedChat()
                } label: {
                    Label(
                        viewModel.selectedChat?.isPinned == true ? "Unpin Chat" : "Pin Chat",
                        systemImage: viewModel.selectedChat?.isPinned == true ? "pin.slash" : "pin"
                    )
                }

                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Label("Delete Chat", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
            }
        }
    }
}
#endif
