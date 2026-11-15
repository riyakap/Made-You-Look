import SwiftUI

/// What a tour tip points at.
enum TourTarget {
    /// One tab in the tab bar.
    case tab(AppStore.Tab)
    /// A specific control on the screen, marked in the view code with `.tourTarget(_:)`.
    case element(String)
}

/// One tip in the first-launch tour.
/// DRAFT COPY: pending approval.
struct TourTip: Identifiable {
    let id: Int
    /// The tab the tip is shown on.
    let screen: AppStore.Tab
    let target: TourTarget
    let title: String
    let message: String

    static let all: [TourTip] = [
        TourTip(
            id: 0,
            screen: .home,
            target: .element("home-for-you"),
            title: "Your picks",
            message: "These products are ranked for your skin tone, concerns, and goals. Anything you already own drops to the bottom."
        ),
        TourTip(
            id: 1,
            screen: .home,
            target: .element("home-looks"),
            title: "Video tutorials",
            message: "Tap a look in this section to see its steps and save its video tutorial."
        ),
        TourTip(
            id: 2,
            screen: .home,
            target: .tab(.profile),
            title: "Your profile",
            message: "Tap Profile to see your beauty profile, your saved counts, and your bag."
        ),
        TourTip(
            id: 3,
            screen: .explore,
            target: .element("explore-look"),
            title: "Makeup looks",
            message: "Each look shows how long it takes and how hard it is. Tap one to see how it's done."
        ),
        TourTip(
            id: 4,
            screen: .saved,
            target: .element("saved-filters"),
            title: "Your saved list",
            message: "Hearts you tap land here. Use these filters to narrow things down to products, looks, or tutorials."
        ),
        TourTip(
            id: 5,
            screen: .profile,
            target: .element("profile-bag"),
            title: "Your bag",
            message: "Products you add wait here until you check out. Tap In my bag to review them and change quantities."
        ),
    ]
}

/// Collects the on-screen frames of views marked with `.tourTarget(_:)`.
struct TourTargetKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]

    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    /// Marks this view as the control a tour tip points at. Use an empty id to mark nothing.
    func tourTarget(_ id: String) -> some View {
        anchorPreference(key: TourTargetKey.self, value: .bounds) { id.isEmpty ? [:] : [id: $0] }
    }
}

/// Walks a new user through the main screens, one tip at a time.
/// Shown on top of `MainTabView` while `AppStore.showingTour` is true.
struct TourOverlay: View {
    @Environment(AppStore.self) private var store
    let anchors: [String: Anchor<CGRect>]

    /// Measured on iPhone 17 Pro: the tab bar's left and right margins, as a share of screen width.
    private let tabBarInsetFraction: CGFloat = 0.082
    private let tailSize = CGSize(width: 22, height: 12)

    var body: some View {
        if store.showingTour, store.tourStep < TourTip.all.count {
            let index = store.tourStep
            let tip = TourTip.all[index]
            GeometryReader { geo in
                switch tip.target {
                case .tab(let tab):
                    elementTip(tip, index: index, rect: tabRect(tab, size: geo.size), size: geo.size)
                case .element(let id):
                    if let anchor = anchors[id] {
                        elementTip(tip, index: index, rect: geo[anchor], size: geo.size)
                    } else {
                        // The control isn't on screen, so show the card without a spotlight.
                        centeredTip(tip, index: index)
                    }
                }
            }
            .ignoresSafeArea()
            .transition(.opacity)
            .sensoryFeedback(.impact(weight: .light), trigger: store.tourStep)
        }
    }

    // MARK: - Layouts

    /// Where one tab sits in the tab bar. Used as the spotlight for tab tips.
    private func tabRect(_ tab: AppStore.Tab, size: CGSize) -> CGRect {
        let inset = size.width * tabBarInsetFraction
        let columnWidth = (size.width - 2 * inset) / CGFloat(AppStore.Tab.allCases.count)
        let tabIndex = AppStore.Tab.allCases.firstIndex(of: tab) ?? 0
        return CGRect(
            x: inset + columnWidth * CGFloat(tabIndex) + 4,
            y: size.height - 86,
            width: columnWidth - 8,
            height: 62
        )
    }

    /// Dims the screen except for a spotlight around one section or control, with the card beside it.
    private func elementTip(_ tip: TourTip, index: Int, rect: CGRect, size: CGSize) -> some View {
        let hole = rect.insetBy(dx: -8, dy: -8)
        // Put the card on the side of the target with more room.
        let cardBelow = (size.height - rect.maxY) > rect.minY
        let tailX = min(max(rect.midX, 36), size.width - 36)

        return ZStack {
            Path { path in
                path.addRect(CGRect(origin: .zero, size: size))
                path.addRoundedRect(in: hole, cornerSize: CGSize(width: 16, height: 16))
            }
            .fill(Color.black.opacity(0.4), style: FillStyle(eoFill: true))
            .allowsHitTesting(true)

            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.surface, lineWidth: 2)
                .frame(width: hole.width, height: hole.height)
                .position(x: hole.midX, y: hole.midY)

            if cardBelow {
                VStack(spacing: 0) {
                    Color.clear.frame(height: max(rect.maxY + 6, 0))
                    tail(pointingDown: false, centerX: tailX)
                    card(for: tip, index: index)
                    Spacer(minLength: 0)
                }
            } else {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    card(for: tip, index: index)
                    tail(pointingDown: true, centerX: tailX)
                    Color.clear.frame(height: max(size.height - rect.minY + 6, 0))
                }
            }
        }
    }

    /// Fallback when the target isn't on screen.
    private func centeredTip(_ tip: TourTip, index: Int) -> some View {
        ZStack {
            Color.black.opacity(0.35)
            card(for: tip, index: index)
        }
    }

    // MARK: - Pieces

    private func tail(pointingDown: Bool, centerX: CGFloat) -> some View {
        Triangle(pointingDown: pointingDown)
            .fill(Theme.surface)
            .frame(width: tailSize.width, height: tailSize.height)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, centerX - tailSize.width / 2)
    }

    private func card(for tip: TourTip, index: Int) -> some View {
        let isLast = index == TourTip.all.count - 1

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(tip.title)
                    .font(Theme.display(22))
                    .foregroundStyle(Theme.ink)
                Spacer()
                progressDots(current: index)
            }

            Text(tip.message)
                .font(Theme.body(14))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button("Skip") { store.skipTour() }
                    .font(Theme.body(13, .semibold))
                    .foregroundStyle(Theme.inkSecondary)

                Spacer()

                if index > 0 {
                    Button("Back") { store.previousTourStep() }
                        .font(Theme.body(14, .semibold))
                        .foregroundStyle(Theme.primary)
                }

                Button(isLast ? "Done" : "Next") { store.nextTourStep() }
                    .buttonStyle(PrimaryButtonStyle(height: 40))
                    .frame(width: 120)
            }
        }
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.cardBorder.opacity(0.6), lineWidth: 1))
        .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
        .padding(.horizontal, 16)
    }

    private func progressDots(current: Int) -> some View {
        HStack(spacing: 5) {
            ForEach(TourTip.all.indices, id: \.self) { i in
                Circle()
                    .fill(i == current ? Theme.primary : Theme.chip)
                    .frame(width: 6, height: 6)
            }
        }
    }
}

/// Small triangle that connects the card to what it points at.
private struct Triangle: Shape {
    var pointingDown: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if pointingDown {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}
