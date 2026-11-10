import SwiftUI

// Pickers for each quiz question. They're also reused by Profile > My Beauty Profile.

struct GoalPicker: View {
    @Binding var selection: Set<Goal>

    var body: some View {
        VStack(spacing: 14) {
            ForEach(Goal.allCases) { goal in
                let isOn = selection.contains(goal)
                Button {
                    selection.toggle(goal)
                } label: {
                    HStack(spacing: 14) {
                        AssetImage(name: goal.imageName, symbol: goal.symbol)
                            .frame(width: 112, height: 80)
                        Text(goal.title)
                            .font(Theme.display(18))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        SelectionCircle(isSelected: isOn)
                            .padding(.trailing, 14)
                    }
                    .cardStyle(cornerRadius: 8)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct SkinTonePicker: View {
    @Binding var selection: SkinTone?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(SkinTone.allCases) { tone in
                let isOn = selection == tone
                Button {
                    selection = tone
                } label: {
                    VStack(spacing: 0) {
                        ZStack {
                            tone.swatch
                            AssetImage(name: tone.imageName, symbol: "face.smiling", tint: tone.swatch)
                        }
                        .frame(height: 112)
                        .clipped()
                        .overlay(alignment: .topTrailing) {
                            SelectionCircle(isSelected: isOn, size: 20).padding(6)
                        }
                        Text(tone.title)
                            .font(Theme.display(14))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .foregroundStyle(isOn ? .white : Theme.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .background(isOn ? Theme.primary : Theme.card)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct LookStylePicker: View {
    @Binding var selection: Set<LookStyle>

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 18), count: 2)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(LookStyle.allCases) { style in
                let isOn = selection.contains(style)
                Button {
                    selection.toggle(style)
                } label: {
                    VStack(spacing: 0) {
                        AssetImage(name: style.imageName, symbol: "face.smiling")
                            .frame(height: 122)
                            .overlay(alignment: .topTrailing) {
                                SelectionCircle(isSelected: isOn, size: 20).padding(6)
                            }
                        Text(style.title)
                            .font(Theme.display(15))
                            .foregroundStyle(isOn ? .white : Theme.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(isOn ? Theme.primary : Theme.card)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ConcernPicker: View {
    @Binding var selection: Set<Concern>

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Concern.allCases) { concern in
                let isOn = selection.contains(concern)
                Button {
                    selection.toggle(concern)
                } label: {
                    HStack(spacing: 18) {
                        Image(systemName: concern.symbol)
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.primary)
                            .frame(width: 28)
                        Text(concern.title)
                            .font(Theme.display(16))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        SelectionCircle(isSelected: isOn, size: 22)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .cardStyle(cornerRadius: 8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ProductPicker: View {
    @Binding var selection: Set<String>
    @State private var query = ""
    @State private var brand: String?

    private var results: [Product] {
        Catalog.products.filter { product in
            (brand == nil || product.brand == brand) &&
            (query.isEmpty || "\(product.brand) \(product.name)".localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            SearchField(text: $query, prompt: "Search products, brands, or looks...")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Catalog.brands, id: \.self) { name in
                        Chip(title: name, isSelected: brand == name) {
                            brand = brand == name ? nil : name
                        }
                    }
                }
            }

            if results.isEmpty {
                EmptyStateView(symbol: "magnifyingglass", title: "No matches", message: "Try another brand or product name.")
            }

            ForEach(results) { product in
                let isOn = selection.contains(product.id)
                Button {
                    selection.toggle(product.id)
                } label: {
                    HStack(spacing: 16) {
                        ProductImage(product: product)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(product.brand)
                                .font(Theme.body(15, .semibold))
                            Text(product.name)
                                .font(Theme.body(12))
                            Text(product.shades.first?.name ?? "")
                                .font(Theme.body(13))
                        }
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if isOn {
                            SelectionCircle(isSelected: true, size: 26)
                        } else {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 26, weight: .light))
                                .foregroundStyle(Theme.primary)
                        }
                    }
                    .padding(14)
                    .cardStyle(cornerRadius: 10)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Single-choice list with an icon and a short hint per option (skin type, budget).
struct HintedChoicePicker<Option: Identifiable & Hashable>: View {
    let options: [Option]
    @Binding var selection: Option?
    let title: (Option) -> String
    let hint: (Option) -> String
    let symbol: (Option) -> String

    var body: some View {
        VStack(spacing: 10) {
            ForEach(options) { option in
                let isOn = selection == option
                Button { selection = option } label: {
                    HStack(spacing: 16) {
                        Image(systemName: symbol(option))
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.primary)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title(option))
                                .font(Theme.display(17))
                                .foregroundStyle(Theme.ink)
                            Text(hint(option))
                                .font(Theme.body(12))
                                .foregroundStyle(Theme.inkSecondary)
                        }
                        Spacer()
                        SelectionCircle(isSelected: isOn, size: 22)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 62)
                    .background(isOn ? Theme.primary.opacity(0.1) : Theme.card, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(isOn ? Theme.primary : Theme.cardBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(title(option)), \(hint(option))")
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
    }
}

struct SkinTypePicker: View {
    @Binding var selection: SkinType?

    var body: some View {
        HintedChoicePicker(options: SkinType.allCases, selection: $selection,
                           title: \.title, hint: \.hint, symbol: \.symbol)
    }
}

struct BudgetPicker: View {
    @Binding var selection: Budget?

    var body: some View {
        HintedChoicePicker(options: Budget.allCases, selection: $selection,
                           title: \.title, hint: \.hint, symbol: \.symbol)
    }
}

struct SearchField: View {
    @Binding var text: String
    let prompt: String
    var onFilter: (() -> Void)? = nil
    var filterActive = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.ink)
            TextField(prompt, text: $text)
                .font(Theme.body(14))
                .foregroundStyle(Theme.ink)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.inkSecondary)
                }
                .accessibilityLabel("Clear search")
            }
            if let onFilter {
                Button(action: onFilter) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(filterActive ? Theme.primary : Theme.ink)
                }
                .accessibilityLabel("Filters")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
        .background(Theme.chip.opacity(0.7), in: Capsule())
    }
}

extension Set {
    mutating func toggle(_ element: Element) {
        if contains(element) { remove(element) } else { insert(element) }
    }
}
