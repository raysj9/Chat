//
//  ChatComposerView.swift
//  Chat
//

import SwiftUI
#if canImport(FoundationModels)

struct ChatComposerView: View {
    @Binding var draft: String
    let canPromptModel: Bool
    let isSending: Bool
    let errorMessage: String?
    let onSubmit: () -> Void

    @FocusState private var isComposerFocused: Bool

    var body: some View {
        GlassEffectContainer(spacing: 18) {
            VStack(spacing: 10) {
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 6)
                }

                HStack(alignment: .bottom, spacing: 12) {
                    TextField("Type here", text: $draft, axis: .vertical)
                        .textFieldStyle(.plain)
                        .focused($isComposerFocused)
                        .disabled(!canPromptModel)
                        .submitLabel(.send)
                        .onSubmit(onSubmit)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .glassEffect(
                            isComposerFocused
                                ? .regular.tint(.white.opacity(0.24)).interactive()
                                : .regular.tint(.white.opacity(0.12)),
                            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                        )

                    Button(action: onSubmit) {
                        Group {
                            if isSending {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.primary)
                            } else {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 13, weight: .bold))
                            }
                        }
                        .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.capsule)
                    .tint(.blue)
                    .disabled(!canSend)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 6)
    }

    private var canSend: Bool {
        canPromptModel && !isSending && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
#endif
