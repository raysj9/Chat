//
//  ContentView.swift
//  Chat
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            FoundationModelChatView()
        } else {
            UnsupportedChatView(
                title: "Foundation Models Requires a Newer OS",
                message: "Run this app on a device or simulator with Foundation Models support to use on-device chat."
            )
        }
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
}
