import SwiftUI

struct ProfileView: View {
    @Environment(AppStore.self) private var store
    @State private var editingTrait: BeautyTrait?
    @State private var editingProfile = false
    @State private var showingNotifications = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 18) {
                    Spacer()
                    Button { showingNotifications = true } label: {
                        Image(systemName: "bell.fill")
                    }
                    .accessibilityLabel("Notifications")
                    NavigationLink(value: Route.settings) {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("Settings")
                }
                .font(.system(size: 20))
                .foregroundStyle(Theme.ink)

                header
                stats
                beautyProfile
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $editingTrait) { trait in
            TraitEditorSheet(trait: trait)
        }
        .sheet(isPresented: $editingProfile) {
            EditProfileSheet()
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsSheet().presentationDetents([.medium])
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            AvatarView(data: store.profile.avatarData, size: 70)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.profile.name)
                    .font(Theme.display(28))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("@\(store.profile.username)")
                    .font(Theme.body(13))
            }
            .foregroundStyle(Theme.ink)
            Spacer()
            Button("Edit Profile") { editingProfile = true }
                .font(Theme.body(14))
                .foregroundStyle(Theme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.primary.opacity(0.12), in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.primary.opacity(0.6), lineWidth: 1))
        }
    }

    private var stats: some View {
        HStack(spacing: 8) {
            Button { store.selectedTab = .saved } label: {
                StatBox(symbol: "heart", value: store.savedCount, label: "Saved")
            }
            NavigationLink(value: Route.bag) {
                StatBox(symbol: "bag", value: store.bagCount, label: "In my bag")
            }
            NavigationLink(value: Route.ownedProducts) {
                StatBox(symbol: "eyedropper.halffull", value: store.profile.ownedProductIDs.count, label: "My products")
            }
            NavigationLink(value: Route.recent) {
                StatBox(symbol: "clock", value: store.recentProductIDs.count, label: "Recent")
            }
        }
        .buttonStyle(.plain)
    }

    private var beautyProfile: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("My Beauty Profile")
                .font(Theme.display(22))
                .foregroundStyle(Theme.ink)
                .padding(.top, 10)

            VStack(spacing: 0) {
                ForEach(BeautyTrait.allCases) { trait in
                    Button { editingTrait = trait } label: {
                        HStack(spacing: 10) {
                            Text(trait.title)
                                .font(Theme.body(14))
                            Spacer(minLength: 8)
                            summary(for: trait)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 14)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if trait != BeautyTrait.allCases.last {
                        Divider().overlay(Theme.cardBorder.opacity(0.5))
                    }
                }
            }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder.opacity(0.6), lineWidth: 1))
        }
    }

    @ViewBuilder
    private func summary(for trait: BeautyTrait) -> some View {
        let profile = store.profile
        switch trait {
        case .skinTone:
            if let tone = profile.skinTone {
                Circle().fill(tone.swatch).frame(width: 18, height: 18)
                    .accessibilityLabel(tone.title)
            } else {
                placeholder
            }
        case .skinType:
            summaryText(profile.skinType?.title)
        case .concerns:
            summaryText(Concern.allCases.filter(profile.concerns.contains).map(\.shortTitle).joined(separator: ", "))
        case .looks:
            summaryText(LookStyle.allCases.filter(profile.looks.contains).map(\.title).joined(separator: ", "))
        case .budget:
            summaryText(profile.budget.map { "\($0.title) (\($0.hint))" })
        case .products:
            summaryText(store.favoriteBrands.joined(separator: ", "))
        }
    }

    private func summaryText(_ text: String?) -> some View {
        Text(text?.isEmpty == false ? text! : "Add")
            .font(Theme.body(11))
            .foregroundStyle(text?.isEmpty == false ? Theme.inkSecondary : Theme.primary)
            .lineLimit(1)
    }

    private var placeholder: some View {
        Text("Add").font(Theme.body(11)).foregroundStyle(Theme.primary)
    }
}

private struct StatBox: View {
    let symbol: String
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 18))
                .foregroundStyle(Theme.primary)
            Text("\(value)")
                .font(Theme.body(15, .semibold))
                .contentTransition(.numericText())
            Text(label)
                .font(Theme.body(11))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(Theme.ink)
        .frame(maxWidth: .infinity)
        .frame(height: 88)
        .background(Theme.surface.opacity(0.8), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.cardBorder.opacity(0.5), lineWidth: 1))
        .animation(.snappy, value: value)
    }
}

// MARK: - Beauty profile editing

enum BeautyTrait: String, CaseIterable, Identifiable {
    case skinTone, skinType, concerns, looks, budget, products

    var id: String { rawValue }

    var title: String {
        switch self {
        case .skinTone: "Skin Tone"
        case .skinType: "Skin Type"
        case .concerns: "Top Concerns"
        case .looks: "Makeup Goals"
        case .budget: "Budget"
        case .products: "Favorite Brands"
        }
    }
}

/// Edits a single beauty-profile answer, reusing the quiz pickers.
struct TraitEditorSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let trait: BeautyTrait

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            Group {
                switch trait {
                case .skinTone:
                    QuizStep(title: "What's your\nskin tone?", subtitle: "This helps us find the best\nproduct matches for you.") {
                        SkinTonePicker(selection: $store.profile.skinTone)
                    }
                case .skinType:
                    QuizStep(title: "What's your\nskin type?", subtitle: "This decides which formulas we suggest.") {
                        SkinTypePicker(selection: $store.profile.skinType)
                    }
                case .concerns:
                    QuizStep(title: "What are your\ntop concerns?", subtitle: "You can select more than one.") {
                        ConcernPicker(selection: $store.profile.concerns)
                    }
                case .looks:
                    QuizStep(title: "What makeup look\ndo you prefer?", subtitle: "You can select more than one.") {
                        LookStylePicker(selection: $store.profile.looks)
                    }
                case .budget:
                    QuizStep(title: "What's your\nbudget?", subtitle: "We'll prioritize products in your price range.") {
                        BudgetPicker(selection: $store.profile.budget)
                    }
                case .products:
                    QuizStep(title: "Products\nyou already use", subtitle: "Your favorite brands come from these.") {
                        ProductPicker(selection: $store.profile.ownedProductIDs)
                    }
                }
            }
            .appBackground()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}
