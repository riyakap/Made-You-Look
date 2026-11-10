import SwiftUI

struct SavedView: View {
    @Environment(AppStore.self) private var store
    @State private var filter: SavedListKind?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Saved")
                    .font(Theme.display(32))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                ChipBar(items: [nil, .products, .looks, .tutorials], selection: $filter) {
                    $0?.title ?? "All"
                }

                if store.savedCount == 0 {
                    EmptyStateView(symbol: "heart", title: "Nothing saved yet", message: "Tap the heart on products and looks to keep them here.")
                }

                if show(.products), !store.savedProducts.isEmpty {
                    section(.products, title: "Products") {
                        ForEach(store.savedProducts) { product in
                            NavigationLink(value: Route.product(product.id)) {
                                ProductTile(product: product, showsHeart: true, width: 115)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                if show(.looks), !store.savedLooks.isEmpty {
                    section(.looks, title: "Makeup Looks") {
                        ForEach(store.savedLooks) { look in
                            NavigationLink(value: Route.look(look.id)) {
                                LookTile(look: look, showsHeart: true, width: 140, height: 135)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                if show(.tutorials), !store.savedTutorials.isEmpty {
                    section(.tutorials, title: "Tutorials") {
                        ForEach(store.savedTutorials) { look in
                            NavigationLink(value: Route.look(look.id)) {
                                LookTile(look: look, showsHeart: true, showsPlay: true, width: 140, height: 135)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    private func show(_ kind: SavedListKind) -> Bool { filter == nil || filter == kind }

    private func section<Content: View>(_ kind: SavedListKind, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title, route: .savedList(kind))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) { content() }
                    .padding(.horizontal, 20)
            }
        }
    }
}

/// "See all" for one saved category.
struct SavedListView: View {
    @Environment(AppStore.self) private var store
    let kind: SavedListKind

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        switch kind {
        case .products:
            ProductListScreen(
                title: "Saved Products",
                products: store.savedProducts,
                empty: ("No saved products", "Tap the heart on a product to save it.")
            )
        case .looks, .tutorials:
            let looks = kind == .looks ? store.savedLooks : store.savedTutorials
            ScrollView {
                if looks.isEmpty {
                    EmptyStateView(symbol: "heart", title: "Nothing saved", message: "Saved \(kind.rawValue) will appear here.")
                }
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(looks) { look in
                        NavigationLink(value: Route.look(look.id)) {
                            LookTile(look: look, showsHeart: true, showsPlay: kind == .tutorials, width: 165, height: 200)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .appBackground()
            .navigationTitle("Saved \(kind.title)")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
