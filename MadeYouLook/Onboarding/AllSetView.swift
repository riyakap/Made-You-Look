import SwiftUI

/// "Onboarding 6": create an account to keep recommendations. Sign-in is mocked locally.
struct AllSetView: View {
    @Environment(AppStore.self) private var store
    @State private var showingEmailSignUp = false
    @State private var showingSignIn = false

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
                Button {
                    store.signUp(name: "", email: "", via: "Google")
                } label: {
                    HStack(spacing: 14) {
                        Image("google_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                        Text("Continue with Google")
                    }
                }
                Button {
                    store.signUp(name: "", email: "", via: "Apple")
                } label: {
                    HStack(spacing: 14) {
                        Image("apple_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                        Text("Continue with Apple")
                    }
                }
                Button("Sign up with email") { showingEmailSignUp = true }
            }
            .buttonStyle(ProviderButtonStyle())
            .padding(.horizontal, 28)
            .padding(.top, 16)

            Spacer()

            HStack(spacing: 4) {
                Text("Already have an account?").foregroundStyle(Theme.inkSecondary)
                Button("Sign In") { showingSignIn = true }
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.primary)
            }
            .font(Theme.body(14))
            .padding(.bottom, 16)
        }
        .appBackground()
        .sheet(isPresented: $showingEmailSignUp) {
            EmailSignUpSheet()
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingSignIn) {
            SignInView().presentationDetents([.large])
        }
    }
}

struct EmailSignUpSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && email.contains("@") && email.contains(".")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sign up with email")
                .font(Theme.display(26))
                .foregroundStyle(Theme.ink)
            LabeledField(title: "Name", text: $name, contentType: .name)
            LabeledField(title: "Email", text: $email, contentType: .emailAddress, keyboard: .emailAddress)
            Button("Create account") {
                dismiss()
                store.signUp(name: name, email: email)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!isValid)
            .opacity(isValid ? 1 : 0.5)
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxHeight: .infinity, alignment: .top)
        .appBackground()
    }
}

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
