import SwiftUI

enum AuthMode {
    case signUp, signIn
}

// MARK: - Sign in

/// Sign-in sheet opened from "Already have an account? Sign In".
/// Checks the login saved on this device. New people have to create an account first.
struct SignInView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var keepSignedIn = true
    @State private var errorMessage: String?
    @State private var providerSheet: AuthProvider?
    @State private var confirmingDemo = false

    private var canSubmit: Bool { !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Welcome back")
                    .font(Theme.display(28))
                    .foregroundStyle(Theme.ink)

                LabeledField(title: "Email", text: $email, contentType: .emailAddress, keyboard: .emailAddress)
                PasswordField(title: "Password", text: $password)

                Toggle("Keep me signed in", isOn: $keepSignedIn)
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.ink)
                    .tint(Theme.primary)

                if let errorMessage {
                    Text(errorMessage)
                        .font(Theme.body(13))
                        .foregroundStyle(.red)
                }

                Button("Sign in") { submit() }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.5)

                HStack(spacing: 10) {
                    Rectangle().fill(Theme.cardBorder).frame(height: 1)
                    Text("or").font(Theme.body(13)).foregroundStyle(Theme.inkSecondary)
                    Rectangle().fill(Theme.cardBorder).frame(height: 1)
                }
                .padding(.vertical, 4)

                VStack(spacing: 12) {
                    Button { providerSheet = .google } label: {
                        HStack(spacing: 14) {
                            Image("google_logo").resizable().scaledToFit().frame(width: 22, height: 22)
                            Text("Continue with Google")
                        }
                    }
                    Button { providerSheet = .apple } label: {
                        HStack(spacing: 14) {
                            Image("apple_logo").resizable().scaledToFit().frame(width: 22, height: 22)
                            Text("Continue with Apple")
                        }
                    }
                }
                .buttonStyle(ProviderButtonStyle())

                Button("Use the demo account") {
                    if store.hasAccount { confirmingDemo = true } else { store.signInDemo() }
                }
                .font(Theme.body(14, .medium))
                .foregroundStyle(Theme.primary)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)

                Text("Accounts are saved on this device only. New here? Close this and tap Get Started.")
                    .font(Theme.body(11))
                    .foregroundStyle(Theme.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .appBackground()
        .sheet(item: $providerSheet) { provider in
            ProviderSignInSheet(provider: provider, mode: .signIn)
                .presentationDetents([.medium, .large])
        }
        .alert("Replace your saved account?", isPresented: $confirmingDemo) {
            Button("Use demo account", role: .destructive) { store.signInDemo() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The demo account replaces the account saved on this device.")
        }
    }

    private func submit() {
        do {
            try store.signIn(email: email, password: password, keepSignedIn: keepSignedIn)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Google / Apple

/// Simulated Google or Apple sign-in, used for both sign-up and sign-in.
/// No Google or Apple account is contacted. Real sign-in needs their SDK and your own client ID.
struct ProviderSignInSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let provider: AuthProvider
    let mode: AuthMode

    @State private var name = ""
    @State private var email = ""
    @State private var keepSignedIn = true
    @State private var errorMessage: String?

    private var logoName: String { provider == .google ? "google_logo" : "apple_logo" }
    private var canSubmit: Bool { !email.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(logoName).resizable().scaledToFit().frame(width: 28, height: 28)
                    Text(mode == .signUp ? "Sign up with \(provider.displayName)" : "Sign in with \(provider.displayName)")
                        .font(Theme.display(24))
                        .foregroundStyle(Theme.ink)
                }

                if mode == .signUp {
                    LabeledField(title: "Name", text: $name, contentType: .name)
                }
                LabeledField(title: "\(provider.displayName) email", text: $email,
                             contentType: .emailAddress, keyboard: .emailAddress)

                Toggle("Keep me signed in", isOn: $keepSignedIn)
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.ink)
                    .tint(Theme.primary)

                if let errorMessage {
                    Text(errorMessage)
                        .font(Theme.body(13))
                        .foregroundStyle(.red)
                }

                Button(mode == .signUp ? "Create account" : "Sign in") { submit() }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.5)

                Text("Prototype: this simulates \(provider.displayName) sign-in on this device and does not contact \(provider.displayName).")
                    .font(Theme.body(11))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .appBackground()
    }

    private func submit() {
        do {
            switch mode {
            case .signUp:
                try store.createAccount(name: name, email: email, password: nil,
                                        provider: provider, keepSignedIn: keepSignedIn)
            case .signIn:
                try store.signIn(with: provider, email: email, keepSignedIn: keepSignedIn)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Password field

struct PasswordField: View {
    let title: String
    @Binding var text: String
    var isNewPassword = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Theme.body(13, .medium))
                .foregroundStyle(Theme.inkSecondary)
            SecureField(title, text: $text)
                .textContentType(isNewPassword ? UITextContentType.newPassword : UITextContentType.password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(Theme.body(16))
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.cardBorder, lineWidth: 1))
        }
    }
}
