import SwiftUI

// MARK: - Images

/// Shows a bundled asset (exported from Figma) or, if it's missing, a soft gradient placeholder
/// with an SF Symbol so the layout still reads correctly.
struct AssetImage: View {
    let name: String
    var symbol: String = "sparkles"
    var tint: Color = Theme.primary

    var body: some View {
        if UIImage(named: name) != nil {
            // The fill image overflows its frame; clip both drawing and hit-testing to the frame
            // so overflow can't steal taps from neighbouring controls.
            Color.clear
                .overlay(Image(name).resizable().scaledToFill().allowsHitTesting(false))
                .clipped()
                .contentShape(Rectangle())
        } else {
            ZStack {
                LinearGradient(
                    colors: [tint.opacity(0.18), tint.opacity(0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: symbol)
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(tint.opacity(0.8))
            }
        }
    }
}

struct ProductImage: View {
    let product: Product

    var body: some View {
        AssetImage(
            name: product.imageName,
            symbol: product.symbol,
            tint: product.shades.first?.color ?? Theme.primary
        )
    }
}

struct LookImage: View {
    let look: Look

    var body: some View {
        AssetImage(name: look.imageName, symbol: "face.smiling", tint: Theme.primaryDark)
    }
}

struct AvatarView: View {
    let data: Data?
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    Color(hex: 0xC9C5C4)
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white)
                        .padding(size * 0.22)
                        .offset(y: size * 0.08)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    var height: CGFloat = 52

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body(17, .medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Theme.primary.opacity(configuration.isPressed ? 0.8 : 1), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SmallPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body(14, .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(Theme.primary.opacity(configuration.isPressed ? 0.8 : 1), in: Capsule())
    }
}

/// White, shadowed capsule used for the sign-up provider buttons.
struct ProviderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body(16, .medium))
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.white.opacity(configuration.isPressed ? 0.7 : 0.95), in: Capsule())
            .shadow(color: Theme.ink.opacity(0.08), radius: 8, y: 3)
    }
}

struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Theme.ink)
                .frame(width: 44, height: 44, alignment: .leading)
        }
        .accessibilityLabel("Back")
    }
}

struct HeartButton: View {
    let isOn: Bool
    var size: CGFloat = 20
    var onColor: Color = Theme.primary
    var offColor: Color = Theme.ink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isOn ? "heart.fill" : "heart")
                .font(.system(size: size, weight: .regular))
                .foregroundStyle(isOn ? onColor : offColor)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: size + 16, height: size + 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: isOn)
        .accessibilityLabel(isOn ? "Remove from saved" : "Save")
    }
}

// MARK: - Selection

struct SelectionCircle: View {
    let isSelected: Bool
    var size: CGFloat = 24

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Theme.primary : Color.white.opacity(0.85))
            Circle()
                .strokeBorder(isSelected ? Theme.primary : Theme.cardBorder, lineWidth: 1)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.45, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .animation(.snappy(duration: 0.2), value: isSelected)
    }
}

struct Chip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.body(14, .medium))
                .foregroundStyle(isSelected ? .white : Theme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.primary : Theme.chip, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

struct ChipBar<Item: Hashable>: View {
    let items: [Item]
    @Binding var selection: Item
    let title: (Item) -> String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Chip(title: title(item), isSelected: item == selection) {
                        withAnimation(.snappy) { selection = item }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Text & layout

struct SectionHeader: View {
    let title: String
    /// Pushes this route when "See all" is tapped.
    var route: Route? = nil
    /// Alternative to `route` for actions that don't push (e.g. switching tabs).
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(Theme.display(22))
                .foregroundStyle(Theme.ink)
            Spacer()
            if let route {
                NavigationLink(value: route) { seeAll }
            } else if let action {
                Button(action: action) { seeAll }
            }
        }
        .padding(.horizontal, 20)
    }

    private var seeAll: some View {
        HStack(spacing: 4) {
            Text("See all")
            Image(systemName: "arrow.right")
        }
        .font(Theme.body(13))
        .foregroundStyle(Theme.ink)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

struct StarRating: View {
    let rating: Double
    let reviews: String
    var size: CGFloat = 13

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: star(for: index))
                    .font(.system(size: size))
                    .foregroundStyle(Theme.ink)
            }
            Text(String(format: "%.1f", rating) + " (\(reviews))")
                .font(Theme.body(size - 1))
                .foregroundStyle(Theme.inkSecondary)
                .lineLimit(1)
                .fixedSize()
                .padding(.leading, 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rated \(String(format: "%.1f", rating)) out of 5, \(reviews) reviews")
    }

    private func star(for index: Int) -> String {
        let value = rating - Double(index)
        if value >= 0.75 { return "star.fill" }
        if value >= 0.25 { return "star.leadinghalf.filled" }
        return "star"
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Theme.primary)
            Text(title)
                .font(Theme.display(20))
                .foregroundStyle(Theme.ink)
            Text(message)
                .font(Theme.body(14))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
    }
}

/// Small confirmation banner ("Added to bag").
struct Toast: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
            Text(message)
        }
        .font(Theme.body(14, .medium))
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Theme.ink.opacity(0.9), in: Capsule())
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

extension View {
    /// Shows a toast at the top for ~1.6s whenever `message` becomes non-nil.
    func toast(_ message: Binding<String?>) -> some View {
        overlay(alignment: .top) {
            if let text = message.wrappedValue {
                Toast(message: text)
                    .padding(.top, 8)
                    .task(id: text) {
                        try? await Task.sleep(for: .seconds(1.6))
                        withAnimation { message.wrappedValue = nil }
                    }
            }
        }
        .animation(.snappy, value: message.wrappedValue)
    }

    func cardStyle(cornerRadius: CGFloat = 14) -> some View {
        background(Theme.card, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(Theme.cardBorder, lineWidth: 1))
    }
}

/// Small "why this was recommended" line shown on cards.
struct ReasonLabel: View {
    let text: String
    var size: CGFloat = 11

    var body: some View {
        Label {
            Text(text).lineLimit(1)
        } icon: {
            Image(systemName: "sparkles")
        }
        .labelStyle(TightLabelStyle())
        .font(Theme.body(size, .medium))
        .foregroundStyle(Theme.primaryDark)
        .accessibilityLabel("Recommended because: \(text)")
    }
}

private struct TightLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.icon
            configuration.title
        }
    }
}
