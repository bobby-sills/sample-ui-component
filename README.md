# MeditationLogin

A SwiftUI login prompt for macOS that looks like a native system dialog: a translucent
material panel with large rounded corners, an app icon, a bold title with secondary
text, rounded fields with an accent focus ring, and full-width capsule **Login** /
**Cancel** buttons. It follows the system's light/dark appearance and accent color.

Requires macOS 13+ and Xcode 15+.

## Try it

```sh
swift run LoginDemo
```

Click **Log In…**. The demo accepts any username with the password `breathe`.

## Use it in your app

Add this package (File ▸ Add Package Dependencies… ▸ Add Local…), then:

```swift
import MeditationLogin

let loginPanel = LoginPromptPanel()   // keep a strong reference

loginPanel.present(over: window, icon: Image("Lotus")) { credentials in
    try await auth.signIn(user: credentials.username, password: credentials.password)
}
```

- `onLogin` is `async throws`. A spinner shows while it runs. If it throws, the error's
  `localizedDescription` appears under the fields, the password is cleared, and the user
  can try again. If it returns normally, the panel closes.
- **Return** submits and **Esc** cancels. Pressing Return in the username field moves to
  the password field.
- `icon` is optional. Without it the prompt shows a 🪷 emoji. To match the screenshot,
  add your lotus artwork to the asset catalog and pass `Image("Lotus")`.
- To embed the prompt in your own layout instead of a floating panel, use the
  `LoginPrompt` view directly.

Store the credentials in the Keychain, never in `UserDefaults`.
