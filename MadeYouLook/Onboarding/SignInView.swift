import SwiftUI

/// Sign-in sheet opened from "Already have an account? Sign In".
///
/// Sign-in is still simulated (there is no server): the password is not checked or stored.
/// If an account already exists on this device, the email has to match it; otherwise the
/// prototype's demo account loads.
struct SignInView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    private var isValid: Bool {
        email.contains("@") && email.contains(".") && password.count >= 6
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Welcome back")
                .font(Theme.display(28))
                .foregroundStyle(Theme.ink)

            LabeledField(title: "Email", text: $email, contentType: .emailAddress, keyboard: .emailAddress)

            VStack(alignment: .leading, spacing: 6) {
                Text("Password")
                    .font(Theme.body(13, .medium))
                    .foregroundStyle(Theme.inkSecondary)
                SecureField("Password (6+ characters)", text: $password)
                    .textContentType(.password)
                    .font(Theme.body(16))
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.cardBorder, lineWidth: 1))
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(Theme.body(13))
                    .foregroundStyle(.red)
            }

            Button("Sign in") { submit() }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!isValid)
                .opacity(isValid ? 1 : 0.5)
                .padding(.top, 4)

            Button("Use the demo account") {
                dismiss()
                store.signInDemo()
            }
            .font(Theme.body(14, .medium))
            .foregroundStyle(Theme.primary)
            .frame(maxWidth: .infinity)

            Text("Prototype only: sign-in is simulated and your password is never saved.")
                .font(Theme.body(11))
                .foregroundStyle(Theme.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 0)
        }
        .padding(24)
        .appBackground()
    }

    private func submit() {
        let saved = store.profile.email
        if store.hasAccount, !saved.isEmpty,
           saved.caseInsensitiveCompare(email.trimmingCharacters(in: .whitespaces)) != .orderedSame {
            errorMessage = "We couldn't find an account for that email on this device."
            return
        }
        dismiss()
        store.signIn()
    }
}
