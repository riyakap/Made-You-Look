import SwiftUI

struct ProductDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    let product: Product

    @State private var shadeIndex = 0
    @State private var quantity = 1
    @State private var imagePage = 0
    @State private var showingDetails = false
    @State private var toast: String?
    @State private var webLink: WebLink?

    private var shade: Shade { product.shades[shadeIndex] }
    private var isOwned: Bool { store.profile.ownedProductIDs.contains(product.id) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                gallery

                VStack(alignment: .leading, spacing: 6) {
                    Text(product.brand)
                        .font(Theme.body(18, .semibold))
                    Text(product.name)
                        .font(Theme.display(20))
                    StarRating(rating: product.rating, reviews: product.reviews)
                        .padding(.top, 4)
                    Text(product.priceText)
                        .font(Theme.body(18, .semibold))
                        .padding(.top, 6)
                }
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 24)

                shadePicker

                Stepper(value: $quantity, in: 1...10) {
                    Text("\(quantity)")
                        .font(Theme.body(16))
                        .monospacedDigit()
                }
                .fixedSize()
                .padding(.horizontal, 24)
                .accessibilityLabel("Quantity \(quantity)")

                Button("Add to Bag") {
                    store.addToBag(product, shadeIndex: shadeIndex, quantity: quantity)
                    toast = "Added \(quantity) to bag"
                }
                .buttonStyle(PrimaryButtonStyle(height: 54))
                .padding(.horizontal, 24)
                .padding(.top, 6)

                buyButton

                Button {
                    store.profile.ownedProductIDs.toggle(product.id)
                } label: {
                    Label(isOwned ? "In my products" : "I already own this",
                          systemImage: isOwned ? "checkmark.circle.fill" : "plus.circle")
                        .font(Theme.body(14, .medium))
                        .foregroundStyle(Theme.primary)
                }
                .frame(maxWidth: .infinity)

                whyForYou

                tutorial

                details
            }
            .padding(.bottom, 30)
        }
        .overlay(alignment: .top) { topBar }
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
        .toast($toast)
        .fullScreenCover(item: $webLink) { link in
            SafariView(url: link.url).ignoresSafeArea()
        }
        .onAppear {
            shadeIndex = store.recommendedShadeIndex(for: product)
            store.markViewed(product)
        }
    }

    private var gallery: some View {
        VStack(spacing: 10) {
            TabView(selection: $imagePage) {
                ForEach(0..<3, id: \.self) { page in
                    AssetImage(
                        name: page == 0 ? product.imageName : "\(product.imageName)_\(page + 1)",
                        symbol: product.symbol,
                        tint: shade.color
                    )
                    .frame(width: 220, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .tag(page)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 230)

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { page in
                    Circle()
                        .fill(page == imagePage ? Theme.primary : Theme.chip)
                        .frame(width: 7, height: 7)
                }
            }
        }
        .padding(.top, 8)
    }

    /// Pinned above the scroll view so Back and Save stay reachable on long pages.
    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Back")
            Spacer()
            HeartButton(isOn: store.isSaved(product: product.id), size: 20) {
                store.toggleSaved(product: product.id)
            }
            .background(.ultraThinMaterial, in: Circle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    private var shadePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("Shade:").font(Theme.body(15, .medium))
                Text(shade.name).font(Theme.body(15))
                if !shade.detail.isEmpty {
                    Text("(\(shade.detail))").font(Theme.body(12)).foregroundStyle(Theme.inkSecondary)
                }
                if let suggestion = store.shadeSuggestion(for: product), suggestion.index == shadeIndex {
                    Text(shade.tone != nil ? "Your match" : "Suggested")
                        .font(Theme.body(11, .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.primary, in: Capsule())
                }
            }
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(product.shades.indices, id: \.self) { index in
                        Button {
                            shadeIndex = index
                        } label: {
                            Circle()
                                .fill(product.shades[index].color)
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Theme.ink, lineWidth: index == shadeIndex ? 2 : 0)
                                        .padding(-4)
                                )
                                .padding(4)
                        }
                        .accessibilityLabel(product.shades[index].name)
                    }
                }
                .padding(.horizontal, 24)
            }

            if let suggestion = store.shadeSuggestion(for: product), let tone = store.profile.skinTone {
                Label {
                    Text("For \(tone.title.lowercased()) skin: \(suggestion.advice)")
                } icon: {
                    Image(systemName: "sparkles")
                }
                .font(Theme.body(12))
                .foregroundStyle(Theme.primaryDark)
                .padding(.horizontal, 24)
            }
        }
    }

    @ViewBuilder
    private var whyForYou: some View {
        let reasons = store.match(for: product).reasons
        if !reasons.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Why it's recommended for you")
                    .font(Theme.display(18))
                    .foregroundStyle(Theme.ink)
                ForEach(reasons, id: \.self) { reason in
                    Label {
                        Text(reason).foregroundStyle(Theme.ink)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.primary)
                    }
                    .font(Theme.body(13))
                }
                if !product.attributes.isEmpty {
                    Text(product.attributes.map(\.title).sorted().joined(separator: " · "))
                        .font(Theme.body(11))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle(cornerRadius: 12)
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }

    /// "Buy at Sephora / Ulta": opens the real product page (or a search) in an in-app browser.
    private var buyButton: some View {
        VStack(spacing: 6) {
            Button {
                webLink = WebLink(url: product.buyLink)
            } label: {
                Label("Buy at \(product.retailerName)", systemImage: "arrow.up.right.square")
                    .font(Theme.body(16, .medium))
                    .foregroundStyle(Theme.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .overlay(Capsule().strokeBorder(Theme.primary, lineWidth: 1.5))
            }
            Text(product.hasDirectBuyPage
                 ? "Opens this product at \(product.retailerName)."
                 : "Opens a \(product.retailerName) search for this product.")
                .font(Theme.body(11))
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(.horizontal, 24)
    }

    /// Written steps plus a YouTube link, for every product.
    private var tutorial: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How to apply")
                .font(Theme.display(18))
                .foregroundStyle(Theme.ink)

            ForEach(Array(product.tutorialSteps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(Theme.body(12, .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Theme.primary, in: Circle())
                    Text(step)
                        .font(Theme.body(14))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Step \(index + 1): \(step)")
            }

            Button {
                openURL(product.videoLink)
            } label: {
                Label(product.hasDirectVideo ? "Watch the tutorial on YouTube" : "Find tutorials on YouTube",
                      systemImage: "play.rectangle.fill")
            }
            .buttonStyle(PrimaryButtonStyle(height: 46))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(cornerRadius: 12)
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 10) {
            DisclosureGroup(isExpanded: $showingDetails) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(product.details)
                    Text("How to use").font(Theme.body(14, .semibold))
                    Text(product.howToUse)
                    if !product.concerns.isEmpty {
                        Text("Good for").font(Theme.body(14, .semibold))
                        Text(product.concerns.map(\.title).sorted().joined(separator: " · "))
                    }
                }
                .font(Theme.body(14))
                .foregroundStyle(Theme.inkSecondary)
                .padding(.top, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            } label: {
                Text("Product Details")
                    .font(Theme.body(16, .medium))
                    .foregroundStyle(Theme.ink)
            }
            .tint(Theme.ink)
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
    }
}
