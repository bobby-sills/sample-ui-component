import AppKit
import MeditationLogin
import SwiftUI

@main
struct LoginDemoApp: App {
    init() {
        // Needed when launched via `swift run` so the app gets a Dock icon and focus.
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup("Meditation") {
            ContentView()
        }
    }
}

private struct DemoLoginError: LocalizedError {
    var errorDescription: String? { "Incorrect username or password." }
}

private struct ContentView: View {
    @State private var presenter = LoginPromptPanel()
    @State private var signedInUser: String?

    var body: some View {
        VStack(spacing: 16) {
            if let signedInUser {
                Text("Welcome, \(signedInUser) 🧘").font(.title2)
                Button("Sign Out") { self.signedInUser = nil }
            } else {
                Text("You're signed out.").foregroundStyle(.secondary)
                Button("Log In…", action: showLogin)
                    .keyboardShortcut("l")
            }
        }
        .frame(minWidth: 480, minHeight: 360)
    }

    private func showLogin() {
        presenter.present(over: NSApp.keyWindow) { credentials in
            // Replace with a call to your real authentication service.
            try await Task.sleep(nanoseconds: 700_000_000)
            guard credentials.password == "breathe" else { throw DemoLoginError() }
            signedInUser = credentials.username
        }
    }
}
