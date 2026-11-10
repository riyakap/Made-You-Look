import SwiftUI

/// Vertical product card used in Home "For You" and Saved.
struct ProductTile: View {
    @Environment(AppStore.self) private var store
    let product: Product
    var showsHeart = false
    var showsReason = false
    var width: CGFloat = 110

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ProductImage(product: product)
                .frame(width: width, height: width * 0.78)
                .background(Theme.chip.opacity(0.5))
                .overlay(alignment: .topTrailing) {
                    if showsHeart {
                        HeartButton(isOn: store.isSaved(product: product.id), size: 14) {
                            store.toggleSaved(product: product.id)
                        }
                    }
                }
            VStack(alignment: .leading, spacing: 3) {
                Text(product.brand)
                    .font(Theme.body(12, .medium))
                    .foregroundStyle(Theme.ink)
                Text(product.cardName)
                    .font(Theme.body(10))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(product.priceText)
                    .font(Theme.body(10, .semibold))
                    .foregroundStyle(Theme.ink)
                if showsReason, let reason = store.topReason(for: product) {
                    ReasonLabel(text: reason, size: 8.5)
                        .padding(.top, 1)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.9))
        }
        .frame(width: width)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.cardBorder.opacity(0.6), lineWidth: 1))
    }
}

/// Horizontal product row used on the Personalized Recommendations list.
struct ProductRow: View {
    @Environment(AppStore.self) private var store
    let product: Product
    var onAdd: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ProductImage(product: product)
                .frame(width: 80, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(product.brand)
                    .font(Theme.body(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(product.cardName)
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.ink)
                Text(product.priceText)
                    .font(Theme.body(15, .semibold))
                    .foregroundStyle(Theme.ink)
                if let reason = store.topReason(for: product) {
                    ReasonLabel(text: reason)
                }
                HStack(alignment: .bottom) {
                    StarRating(rating: product.rating, reviews: product.reviews, size: 9)
                    Spacer(minLength: 4)
                    Button("Add to bag", action: onAdd)
                        .buttonStyle(SmallPillButtonStyle())
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .cardStyle(cornerRadius: 12)
        .overlay(alignment: .topTrailing) {
            HeartButton(isOn: store.isSaved(product: product.id), size: 19) {
                store.toggleSaved(product: product.id)
            }
            .padding(6)
        }
    }
}

/// Portrait look thumbnail used on Home "Looks You'll Love" and Saved.
struct LookTile: View {
    @Environment(AppStore.self) private var store
    let look: Look
    var showsHeart = false
    var showsPlay = false
    var width: CGFloat = 130
    var height: CGFloat = 130

    var body: some View {
        LookImage(look: look)
            .frame(width: width, height: height)
            .overlay(alignment: .bottom) {
                if !showsPlay {
                    Text(look.title)
                        .font(Theme.body(14, .medium))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if showsPlay {
                    Image(systemName: "play.circle")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(.white)
                        .padding(8)
                }
            }
            .overlay(alignment: .topTrailing) {
                if showsHeart {
                    let saved = showsPlay ? store.isSaved(tutorial: look.id) : store.isSaved(look: look.id)
                    HeartButton(isOn: saved, size: 14) {
                        if showsPlay { store.toggleSaved(tutorial: look.id) } else { store.toggleSaved(look: look.id) }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// Large card used in Explore ("Everyday Natural Look · 5 min • Easy").
struct LookCard: View {
    @Environment(AppStore.self) private var store
    let look: Look

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LookImage(look: look)
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .bottomLeading) {
                    Image(systemName: "play.circle")
                        .font(.system(size: 30, weight: .light))
                        .foregroundStyle(Theme.primary)
                        .padding(16)
                }
            VStack(alignment: .leading, spacing: 4) {
                Text(look.title)
                    .font(Theme.display(20))
                    .foregroundStyle(Theme.ink)
                Text(look.meta)
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.inkSecondary)
                if let reason = store.lookReason(for: look) {
                    ReasonLabel(text: reason, size: 12)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cardStyle(cornerRadius: 16)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
