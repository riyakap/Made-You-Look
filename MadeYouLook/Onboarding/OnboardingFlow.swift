import SwiftUI

/// The five-question beauty quiz ("Onboarding 1–5" frames).
struct OnboardingFlow: View {
    @Environment(AppStore.self) private var store
    @State private var step: Int
    @State private var goingForward = true

    init(initialStep: Int = 0) {
        _step = State(initialValue: initialStep)
    }

    private let stepCount = 7

    var body: some View {
        @Bindable var store = store
        VStack(spacing: 0) {
            topBar
            Group {
                switch step {
                case 0:
                    QuizStep(title: "What are you\nlooking for?", subtitle: "You can select more than one.") {
                        GoalPicker(selection: $store.profile.goals)
                    }
                case 1:
                    QuizStep(title: "What's your\nskin tone?", subtitle: "This helps us find the best\nproduct matches for you.") {
                        SkinTonePicker(selection: $store.profile.skinTone)
                    }
                case 2:
                    QuizStep(title: "What's your\nskin type?", subtitle: "This decides which formulas we suggest.") {
                        SkinTypePicker(selection: $store.profile.skinType)
                    }
                case 3:
                    QuizStep(title: "What makeup look\ndo you prefer?", subtitle: "You can select more than one.") {
                        LookStylePicker(selection: $store.profile.looks)
                    }
                case 4:
                    QuizStep(title: "What are your\ntop concerns?", subtitle: "You can select more than one.") {
                        ConcernPicker(selection: $store.profile.concerns)
                    }
                case 5:
                    QuizStep(title: "What's your\nbudget?", subtitle: "We'll prioritize products in your price range.") {
                        BudgetPicker(selection: $store.profile.budget)
                    }
                default:
                    QuizStep(title: "Add products\nyou already use", subtitle: "Get better recommendations based\non what you own. You can skip this step.") {
                        ProductPicker(selection: $store.profile.ownedProductIDs)
                    }
                }
            }
            .id(step)
            .transition(.asymmetric(
                insertion: .move(edge: goingForward ? .trailing : .leading).combined(with: .opacity),
                removal: .move(edge: goingForward ? .leading : .trailing).combined(with: .opacity)
            ))
            .frame(maxHeight: .infinity, alignment: .top)

            bottomBar
        }
        .appBackground()
    }

    private var topBar: some View {
        HStack {
            BackButton { go(to: step - 1) }
            Spacer()
            HStack(spacing: 4) {
                ForEach(0..<stepCount, id: \.self) { index in
                    Capsule()
                        .fill(index == step ? Theme.primary : Theme.chip.opacity(0.8))
                        .frame(width: index == step ? 34 : 14, height: 6)
                }
            }
            .animation(.snappy, value: step)
            Spacer()
            Text("\(step + 1)/\(stepCount)")
                .font(Theme.body(12))
                .foregroundStyle(Theme.inkSecondary)
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var bottomBar: some View {
        if step == stepCount - 1 {
            HStack(spacing: 16) {
                Button("Skip") {
                    store.profile.ownedProductIDs = []
                    store.finishOnboarding()
                }
                .font(Theme.body(18))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)

                Button {
                    store.finishOnboarding()
                } label: {
                    HStack(spacing: 8) {
                        Text("Finish")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(PrimaryButtonStyle(height: 56))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        } else {
            Button("Next") { go(to: step + 1) }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 28)
                .padding(.bottom, 12)
                .opacity(canContinue ? 1 : 0)
                .disabled(!canContinue)
                .animation(.snappy, value: canContinue)
        }
    }

    /// Matches the prototype: Next only appears once an answer is chosen.
    private var canContinue: Bool {
        switch step {
        case 0: !store.profile.goals.isEmpty
        case 1: store.profile.skinTone != nil
        case 2: store.profile.skinType != nil
        case 3: !store.profile.looks.isEmpty
        case 4: !store.profile.concerns.isEmpty
        case 5: store.profile.budget != nil
        default: true
        }
    }

    private func go(to newStep: Int) {
        if newStep < 0 {
            store.phase = .welcome
            return
        }
        goingForward = newStep > step
        withAnimation(.easeInOut(duration: 0.3)) { step = min(newStep, stepCount - 1) }
    }
}

/// Title + subtitle + content layout shared by every quiz question (and profile editing).
struct QuizStep<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text(title)
                    .font(Theme.display(30))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(Theme.body(14))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.inkSecondary)
                content
                    .padding(.top, 12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }
}
