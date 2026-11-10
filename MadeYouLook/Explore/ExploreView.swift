import SwiftUI

/// "Makeup Looks" tab.
struct ExploreView: View {
    @Environment(AppStore.self) private var store
    @State private var style: LookStyle?

    private var looks: [Look] {
        store.recommendedLooks.filter { style == nil || $0.styles.contains(style!) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Makeup Looks")
                    .font(Theme.display(32))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                ChipBar(items: [nil] + LookStyle.allCases.map(Optional.some), selection: $style) {
                    $0?.chipTitle ?? "All"
                }

                LazyVStack(spacing: 20) {
                    ForEach(looks) { look in
                        NavigationLink(value: Route.look(look.id)) {
                            LookCard(look: look)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 24)
        }
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct LookDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let look: Look
    @State private var toast: String?

    private var products: [Product] { look.productIDs.compactMap(Catalog.product) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                LookImage(look: look)
                    .frame(height: 380)
                    .frame(maxWidth: .infinity)
                    .clipped()

                VStack(alignment: .leading, spacing: 8) {
                    Text(look.title)
                        .font(Theme.display(28))
                    Text(look.meta)
                        .font(Theme.body(14))
                        .foregroundStyle(Theme.inkSecondary)
                    Text(look.summary)
                        .font(Theme.body(15))
                        .padding(.top, 4)
                    HStack(spacing: 8) {
                        ForEach(Array(look.styles).sorted { $0.rawValue < $1.rawValue }) { style in
                            Text(style.chipTitle)
                                .font(Theme.body(12, .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Theme.chip, in: Capsule())
                        }
                    }
                    .padding(.top, 4)
                }
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 20)

                Button {
                    store.toggleSaved(tutorial: look.id)
                    toast = store.isSaved(tutorial: look.id) ? "Tutorial saved" : "Tutorial removed"
                } label: {
                    Label(store.isSaved(tutorial: look.id) ? "Tutorial saved" : "Save tutorial",
                          systemImage: store.isSaved(tutorial: look.id) ? "play.circle.fill" : "play.circle")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Products in this look")
                        .font(Theme.display(22))
                        .foregroundStyle(Theme.ink)
                    ForEach(products) { product in
                        NavigationLink(value: Route.product(product.id)) {
                            ProductRow(product: product) {
                                store.addToBag(product)
                                toast = "Added to bag"
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 30)
        }
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .top) {
            // Pinned so Back and Save stay reachable while scrolling.
            HStack {
                circleButton("chevron.left") { dismiss() }
                Spacer()
                HeartButton(isOn: store.isSaved(look: look.id), size: 20, offColor: Theme.ink) {
                    store.toggleSaved(look: look.id)
                }
                .background(.ultraThinMaterial, in: Circle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
        .toast($toast)
    }

    private func circleButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityLabel("Back")
    }
}
