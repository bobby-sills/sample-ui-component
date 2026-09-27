import SwiftUI

/// The username and password the user entered.
public struct LoginCredentials: Sendable, Equatable {
    public let username: String
    public let password: String
}

/// A compact login dialog styled after native macOS alerts: a translucent
/// dark/light material panel, an app icon, a bold title, secondary message
/// text, rounded input fields and full-width capsule buttons.
///
/// `onLogin` is async and throwing: while it runs the prompt shows a spinner,
/// and if it throws, the error's `localizedDescription` is shown in the prompt
/// so the user can try again. Return normally to indicate success.
public struct LoginPrompt: View {
    private enum Field: Hashable { case username, password }

    private let title: String
    private let message: String
    private let icon: Image?
    private let onLogin: @MainActor (LoginCredentials) async throws -> Void
    private let onCancel: () -> Void

    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @FocusState private var focusedField: Field?

    public init(
        title: String = "Login to your meditation app",
        message: String = "Enter your account username and password to continue to the meditation",
        icon: Image? = nil,
        onLogin: @escaping @MainActor (LoginCredentials) async throws -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.onLogin = onLogin
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 16)

            VStack(spacing: 8) {
                TextField("Username", text: $username)
                    .textContentType(.username)
                    .focused($focusedField, equals: .username)
                    .onSubmit { focusedField = .password }
                    .promptField(isFocused: focusedField == .username)

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .onSubmit(submit)
                    .promptField(isFocused: focusedField == .password)
            }
            .disabled(isSubmitting)

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .transition(.opacity)
            }

            VStack(spacing: 8) {
                Button(action: submit) {
                    ZStack {
                        Text("Login").opacity(isSubmitting ? 0 : 1)
                        if isSubmitting {
                            ProgressView().controlSize(.small).tint(.white)
                        }
                    }
                }
                .buttonStyle(PromptButtonStyle(isProminent: true))
                .keyboardShortcut(.defaultAction)
                .disabled(!canSubmit)

                Button("Cancel", action: onCancel)
                    .buttonStyle(PromptButtonStyle(isProminent: false))
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.top, 20)
        }
        .padding(20)
        .frame(width: 280)
        .background(PromptBackground())
        .animation(.easeInOut(duration: 0.15), value: errorMessage)
        .onAppear {
            // Defer so the hosting window is key before focus is assigned.
            DispatchQueue.main.async { focusedField = .username }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let icon {
                    icon.resizable().scaledToFit()
                } else {
                    Text("🪷").font(.system(size: 52))
                }
            }
            .frame(width: 64, height: 64, alignment: .leading)
            .padding(.bottom, 6)
            .accessibilityHidden(true)

            Text(title)
                .font(.system(size: 15, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)

            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var canSubmit: Bool {
        !isSubmitting && !username.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    private func submit() {
        guard canSubmit else { return }
        let credentials = LoginCredentials(username: username, password: password)
        errorMessage = nil
        isSubmitting = true
        Task { @MainActor in
            defer { isSubmitting = false }
            do {
                try await onLogin(credentials)
            } catch {
                errorMessage = error.localizedDescription
                password = ""
                focusedField = .password
            }
        }
    }
}

// MARK: - Styling

/// Rounded, subtly filled input field with a macOS-style accent focus ring.
private struct PromptFieldModifier: ViewModifier {
    let isFocused: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        content
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(shape.fill(Color.primary.opacity(0.07)))
            .overlay(
                shape
                    .inset(by: -2)
                    .strokeBorder(Color.accentColor.opacity(isFocused ? 0.6 : 0), lineWidth: 3)
            )
            .animation(.easeOut(duration: 0.12), value: isFocused)
    }
}

private extension View {
    func promptField(isFocused: Bool) -> some View {
        modifier(PromptFieldModifier(isFocused: isFocused))
    }
}

/// Full-width capsule button: accent-filled when prominent, translucent grey otherwise.
private struct PromptButtonStyle: ButtonStyle {
    let isProminent: Bool
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: isProminent ? .semibold : .regular))
            .foregroundStyle(isProminent ? Color.white : Color.primary)
            .frame(maxWidth: .infinity, minHeight: 20)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(isProminent ? Color.accentColor : Color.primary.opacity(0.1))
            )
            .contentShape(Capsule(style: .continuous))
            .brightness(configuration.isPressed ? -0.08 : 0)
            .opacity(isEnabled ? 1 : 0.55)
    }
}

/// Translucent window-style material with large continuous corners and a hairline border.
private struct PromptBackground: View {
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        VisualEffectView(material: .hudWindow)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
    }
}

private struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
    }
}

struct LoginPrompt_Previews: PreviewProvider {
    static var previews: some View {
        LoginPrompt(onLogin: { _ in }, onCancel: {})
            .padding(40)
    }
}
