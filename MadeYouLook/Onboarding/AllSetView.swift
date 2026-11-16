import SwiftUI

private enum SignUpSheet: String, Identifiable {
    case email, google, apple, signIn

    var id: String { rawValue }
}

/// "Onboarding 6": every new person creates an account here before reaching the app.
/// The login is saved on this device (see AuthService.swift). Google / Apple are simulated.
struct AllSetView: View {
    @Environment(AppStore.self) private var store
    @State private var sheet: SignUpSheet?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                BackButton { store.phase = .onboarding }
                Spacer()
            }
            .padding(.horizontal, 20)

            Image(systemName: "gift.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.primary)
                .padding(.top, 20)

            Text("You're all set!")
                .font(Theme.display(32))
                .foregroundStyle(Theme.ink)

            (Text("Create an account to save your recommendations, track products, and get ")
             + Text("10% off").foregroundColor(Theme.primary).bold()
             + Text(" your first order."))
                .font(Theme.body(15))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            VStack(spacing: 14) {
                Button { sheet = .google } label: {
                    HStack(spacing: 14) {
                        Image("google_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                        Text("Continue with Google")
                    }
                }
                Button { sheet = .apple } label: {
                    HStack(spacing: 14) {
                        Image("apple_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                        Text("Continue with Apple")
                    }
                }
                Button("Sign up with email") { sheet = .email }
            }
            .buttonStyle(ProviderButtonStyle())
            .padding(.horizontal, 28)
            .padding(.top, 16)

            Spacer()

            HStack(spacing: 4) {
                Text("Already have an account?").foregroundStyle(Theme.inkSecondary)
                Button("Sign In") { sheet = .signIn }
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.primary)
            }
            .font(Theme.body(14))
            .padding(.bottom, 16)
        }
        .appBackground()
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .email:
                EmailSignUpSheet().presentationDetents([.large])
            case .google:
                ProviderSignInSheet(provider: .google, mode: .signUp).presentationDetents([.medium, .large])
            case .apple:
                ProviderSignInSheet(provider: .apple, mode: .signUp).presentationDetents([.medium, .large])
            case .signIn:
                SignInView().presentationDetents([.large])
            }
        }
    }
}

// MARK: - Email sign-up

struct EmailSignUpSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var keepSignedIn = true
    @State private var errorMessage: String?

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !email.trimmingCharacters(in: .whitespaces).isEmpty
            && !password.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sign up with email")
                    .font(Theme.display(26))
                    .foregroundStyle(Theme.ink)

                LabeledField(title: "Name", text: $name, contentType: .name)
                LabeledField(title: "Email", text: $email, contentType: .emailAddress, keyboard: .emailAddress)
                PasswordField(title: "Password", text: $password, isNewPassword: true)
                Text("Use at least 8 characters.")
                    .font(Theme.body(12))
                    .foregroundStyle(Theme.inkSecondary)
                    .padding(.top, -8)
                PasswordField(title: "Confirm password", text: $confirmPassword, isNewPassword: true)

                Toggle("Keep me signed in", isOn: $keepSignedIn)
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.ink)
                    .tint(Theme.primary)

                if let errorMessage {
                    Text(errorMessage)
                        .font(Theme.body(13))
                        .foregroundStyle(.red)
                }

                Button("Create account") { submit() }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.5)
                    .padding(.top, 4)

                Text("Your login is saved on this device.")
                    .font(Theme.body(11))
                    .foregroundStyle(Theme.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .appBackground()
    }

    private func submit() {
        guard password == confirmPassword else {
            errorMessage = AuthError.passwordsDontMatch.localizedDescription
            return
        }
        do {
            try store.createAccount(name: name, email: email, password: password,
                                    provider: .email, keepSignedIn: keepSignedIn)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Text field

struct LabeledField: View {
    let title: String
    @Binding var text: String
    var contentType: UITextContentType? = nil
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Theme.body(13, .medium))
                .foregroundStyle(Theme.inkSecondary)
            TextField(title, text: $text)
                .textContentType(contentType)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .autocorrectionDisabled()
                .font(Theme.body(16))
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.cardBorder, lineWidth: 1))
        }
    }
}
