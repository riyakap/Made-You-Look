import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var photoItem: PhotosPickerItem?
    @State private var confirmingLogout = false
    @AppStorage(SoundEffects.enabledKey) private var soundEffects = true

    var body: some View {
        @Bindable var store = store
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ZStack {
                    Text("Settings")
                        .font(Theme.display(30))
                    HStack {
                        BackButton { dismiss() }
                        Spacer()
                    }
                }
                .foregroundStyle(Theme.ink)

                sectionTitle("Basic Information")
                SettingsGroup {
                    NavigationLink { TextSettingView(title: "Name", text: $store.profile.name) } label: {
                        SettingsRow(title: "Name", value: store.profile.name)
                    }
                    NavigationLink { TextSettingView(title: "Username", text: $store.profile.username) } label: {
                        SettingsRow(title: "Username", value: "@\(store.profile.username)")
                    }
                    NavigationLink {
                        TextSettingView(title: "Email", text: $store.profile.email, keyboard: .emailAddress)
                    } label: {
                        SettingsRow(title: "Email", value: store.profile.email.isEmpty ? "Add" : store.profile.email)
                    }
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        SettingsRow(title: "Profile Picture") {
                            AvatarView(data: store.profile.avatarData, size: 28)
                        }
                    }
                }

                sectionTitle("Account").padding(.top, 14)
                SettingsGroup {
                    NavigationLink { NotificationSettingsView() } label: {
                        SettingsRow(title: "Notification Preferences")
                    }
                    NavigationLink { PrivacySettingsView() } label: {
                        SettingsRow(title: "Privacy & Sharing")
                    }
                    NavigationLink { ConnectedAccountsView() } label: {
                        SettingsRow(title: "Connected Accounts")
                    }
                    NavigationLink { ResearchView() } label: {
                        SettingsRow(title: "How Recommendations Work")
                    }
                    Toggle(isOn: $soundEffects) {
                        Text("Sound Effects").font(Theme.body(14))
                    }
                    .tint(Theme.primary)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .onChange(of: soundEffects) { _, isOn in
                        if isOn { SoundEffects.shared.play(.save) }  // preview
                    }
                }

                Button("Logout") { confirmingLogout = true }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 36)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("Log out of Made You Look?", isPresented: $confirmingLogout, titleVisibility: .visible) {
            Button("Logout", role: .destructive) { store.logOut() }
        } message: {
            Text("Your saved items and bag on this device will be cleared.")
        }
        .onChange(of: photoItem) { _, item in
            Task { await loadPhoto(item) }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(Theme.display(22))
            .foregroundStyle(Theme.ink)
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let data = try? await item?.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        // Downscale so the avatar stays small in UserDefaults.
        let side: CGFloat = 300
        let scale = side / min(image.size.width, image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        await MainActor.run {
            store.profile.avatarData = resized.jpegData(compressionQuality: 0.8)
        }
    }
}

// MARK: - Building blocks

struct SettingsGroup<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            Group(subviews: content) { subviews in
                ForEach(subviews.indices, id: \.self) { index in
                    subviews[index]
                    if index < subviews.count - 1 {
                        Divider().overlay(Theme.cardBorder.opacity(0.5))
                    }
                }
            }
        }
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder.opacity(0.6), lineWidth: 1))
    }
}

struct SettingsRow<Accessory: View>: View {
    let title: String
    var value: String? = nil
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(spacing: 10) {
            Text(title).font(Theme.body(14))
            Spacer()
            if let value {
                Text(value)
                    .font(Theme.body(12))
                    .foregroundStyle(Theme.inkSecondary)
                    .lineLimit(1)
            }
            accessory
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 14)
        .frame(height: 44)
        .contentShape(Rectangle())
    }
}

extension SettingsRow where Accessory == EmptyView {
    init(title: String, value: String? = nil) {
        self.init(title: title, value: value) { EmptyView() }
    }
}

struct TextSettingView: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    @State private var draft = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading) {
            LabeledField(title: title, text: $draft, keyboard: keyboard)
            Spacer()
        }
        .padding(20)
        .appBackground()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            Button("Save") {
                text = draft.trimmingCharacters(in: .whitespaces)
                dismiss()
            }
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .onAppear { draft = text }
    }
}

struct NotificationSettingsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store
        Form {
            Toggle("Push notifications", isOn: $store.settings.pushNotifications)
            Toggle("New product matches", isOn: $store.settings.newProductAlerts)
            Toggle("Email updates & offers", isOn: $store.settings.emailUpdates)
        }
        .settingsFormStyle(title: "Notifications")
    }
}

struct PrivacySettingsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store
        Form {
            Section(footer: Text("A private profile hides your saved looks from other users.")) {
                Toggle("Private profile", isOn: $store.settings.privateProfile)
            }
            Section(footer: Text("Use your beauty profile to personalize offers.")) {
                Toggle("Personalized offers", isOn: $store.settings.personalizedAds)
            }
        }
        .settingsFormStyle(title: "Privacy & Sharing")
    }
}

struct ConnectedAccountsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store
        Form {
            Section(footer: Text("Account linking is simulated in this prototype.")) {
                Toggle(isOn: $store.settings.googleConnected) {
                    Label("Google", systemImage: "g.circle")
                }
                Toggle(isOn: $store.settings.appleConnected) {
                    Label("Apple", systemImage: "apple.logo")
                }
            }
        }
        .settingsFormStyle(title: "Connected Accounts")
    }
}

private extension View {
    func settingsFormStyle(title: String) -> some View {
        self
            .tint(Theme.primary)
            .scrollContentBackground(.hidden)
            .appBackground()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
    }
}

/// "Edit Profile" from the profile header.
struct EditProfileSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var username = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                AvatarView(data: store.profile.avatarData, size: 90)
                LabeledField(title: "Name", text: $name, contentType: .name)
                LabeledField(title: "Username", text: $username, contentType: .username)
                Spacer()
            }
            .padding(24)
            .appBackground()
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.profile.name = name.trimmingCharacters(in: .whitespaces)
                        store.profile.username = username
                            .trimmingCharacters(in: .whitespaces)
                            .trimmingCharacters(in: CharacterSet(charactersIn: "@"))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || username.isEmpty)
                }
            }
            .onAppear {
                name = store.profile.name
                username = store.profile.username
            }
        }
        .presentationDetents([.medium])
    }
}
