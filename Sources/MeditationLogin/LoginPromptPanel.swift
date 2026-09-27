import AppKit
import SwiftUI

/// Presents a `LoginPrompt` in a borderless, transparent floating panel so the
/// prompt's own rounded material is the whole window, like a native alert.
///
/// Keep a strong reference to the presenter while the prompt is on screen.
@MainActor
public final class LoginPromptPanel {
    private var panel: NSPanel?
    private weak var parentWindow: NSWindow?

    public init() {}

    public var isPresented: Bool { panel != nil }

    /// Shows the prompt centred over `parent` (or the screen, if `nil`).
    /// The panel closes itself after a successful login or a cancel.
    public func present(
        over parent: NSWindow?,
        title: String = "Login to your meditation app",
        message: String = "Enter your account username and password to continue to the meditation",
        icon: Image? = nil,
        onLogin: @escaping @MainActor (LoginCredentials) async throws -> Void,
        onCancel: @escaping () -> Void = {}
    ) {
        dismiss()

        let prompt = LoginPrompt(
            title: title,
            message: message,
            icon: icon,
            onLogin: { [weak self] credentials in
                try await onLogin(credentials)
                self?.dismiss()
            },
            onCancel: { [weak self] in
                self?.dismiss()
                onCancel()
            }
        )

        let hostingView = NSHostingView(rootView: prompt)
        let size = hostingView.fittingSize

        let panel = KeyablePanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.contentView = hostingView

        if let parent {
            let frame = parent.frame
            panel.setFrameOrigin(NSPoint(
                x: frame.midX - size.width / 2,
                y: frame.midY - size.height / 2
            ))
            parent.addChildWindow(panel, ordered: .above)
        } else {
            panel.level = .modalPanel
            panel.center()
        }

        self.panel = panel
        self.parentWindow = parent
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        // Recompute the shadow from the rounded, non-transparent content.
        panel.invalidateShadow()
    }

    public func dismiss() {
        guard let panel else { return }
        parentWindow?.removeChildWindow(panel)
        panel.orderOut(nil)
        self.panel = nil
        self.parentWindow = nil
    }
}

/// Borderless panels refuse key status by default, which would stop the text
/// fields from receiving keyboard input.
private final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
