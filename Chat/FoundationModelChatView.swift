//
//  FoundationModelChatView.swift
//  Chat
//

import SwiftUI
#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
struct FoundationModelChatView: View {
    @State private var viewModel = ChatViewModel()
    @State private var draft = ""
    @State private var isShowingRenamePrompt = false
    @State private var isShowingDeleteConfirmation = false
    @State private var renameDraft = ""

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationSplitView {
            List(selection: $viewModel.selectedChatID) {
                ForEach(viewModel.chats) { chat in
                    ChatListRow(chat: chat)
                        .tag(chat.id)
                }
                .onDelete(perform: viewModel.deleteChats)
            }
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
    }

    private func submitDraft() {
        let prompt = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        draft = ""

        Task {
            await viewModel.send(prompt)
        }
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
