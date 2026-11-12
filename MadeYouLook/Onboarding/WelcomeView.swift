import SwiftUI

/// "Initial Launch" frame: full-bleed product photo, wordmark, Get Started.
struct WelcomeView: View {
    @Environment(AppStore.self) private var store
    @State private var showingSignIn = false

    var body: some View {
        ZStack {
            background
            VStack(spacing: 10) {
                Spacer()
                Text("Made You\nLook")
                    .font(Theme.display(46))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.ink)
                Text("Beauty, Made Personal")
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.ink.opacity(0.8))
                Spacer()
                Button {
                    store.startOnboarding()
                } label: {
                    HStack(spacing: 8) {
                        Text("Get Started")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 52)

                HStack(spacing: 4) {
                    Text("Already have an account?")
                    Button("Sign In") { showingSignIn = true }
                        .fontWeight(.semibold)
                }
                .font(Theme.body(14))
                .foregroundStyle(hasPhoto ? .white : Theme.ink)
                .shadow(color: .black.opacity(hasPhoto ? 0.35 : 0), radius: 3)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showingSignIn) {
            SignInView().presentationDetents([.large])
        }
    }

    private var hasPhoto: Bool { UIImage(named: "splash_bg") != nil }

    @ViewBuilder
    private var background: some View {
        if hasPhoto {
            Image("splash_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(
                    // Soft wash so the title stays legible over the photo.
                    RadialGradient(
                        colors: [Theme.background.opacity(0.55), .clear],
                        center: .center, startRadius: 10, endRadius: 260
                    )
                    .ignoresSafeArea()
                )
        } else {
            ZStack {
                AppBackground()
                ForEach(Array(floatingSymbols.enumerated()), id: \.offset) { _, item in
                    Image(systemName: item.symbol)
                        .font(.system(size: item.size, weight: .ultraLight))
                        .foregroundStyle(Theme.primary.opacity(0.35))
                        .rotationEffect(.degrees(item.angle))
                        .position(x: item.x, y: item.y)
                }
            }
            .ignoresSafeArea()
        }
    }

    private var floatingSymbols: [(symbol: String, size: CGFloat, angle: Double, x: CGFloat, y: CGFloat)] {
        [
            ("paintbrush.pointed.fill", 70, -35, 90, 170),
            ("circle.circle", 80, 0, 300, 200),
            ("drop.fill", 50, 20, 320, 520),
            ("eyedropper.halffull", 70, 30, 80, 600),
            ("sparkles", 40, 0, 250, 690),
        ]
    }
}
