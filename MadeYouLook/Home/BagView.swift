import SwiftUI

struct BagView: View {
    @Environment(AppStore.self) private var store
    @State private var showingCheckout = false

    /// First-order discount promised on the sign-up screen.
    private var discount: Double { (store.bagSubtotal * 0.10 * 100).rounded() / 100 }

    var body: some View {
        Group {
            if store.bag.isEmpty {
                EmptyStateView(symbol: "bag", title: "Your bag is empty", message: "Tap “Add to bag” on any product to see it here.")
                    .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.bag) { item in
                        if let product = Catalog.product(item.productID) {
                            BagRow(item: item, product: product)
                                .listRowBackground(Theme.surface)
                        }
                    }
                    .onDelete { offsets in
                        store.bag.remove(atOffsets: offsets)
                    }

                    Section {
                        summaryRow("Subtotal", Product.formatPrice(store.bagSubtotal))
                        summaryRow("First order (10% off)", "−" + Product.formatPrice(discount))
                        summaryRow("Total", Product.formatPrice(store.bagSubtotal - discount), bold: true)
                    }
                    .listRowBackground(Theme.surface)

                    Section {
                        Button("Checkout") { showingCheckout = true }
                            .buttonStyle(PrimaryButtonStyle())
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .appBackground()
        .navigationTitle("My Bag")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Demo checkout", isPresented: $showingCheckout) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Checkout isn't connected to a store in this prototype. Your bag stays saved.")
        }
    }

    private func summaryRow(_ title: String, _ value: String, bold: Bool = false) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
        }
        .font(Theme.body(15, bold ? .semibold : .regular))
        .foregroundStyle(Theme.ink)
    }
}

private struct BagRow: View {
    @Environment(AppStore.self) private var store
    let item: BagItem
    let product: Product

    var body: some View {
        HStack(spacing: 14) {
            ProductImage(product: product)
                .frame(width: 60, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 3) {
                Text(product.brand).font(Theme.body(15, .semibold))
                Text(product.cardName).font(Theme.body(13))
                HStack(spacing: 6) {
                    Circle().fill(product.shades[item.shadeIndex].color).frame(width: 12, height: 12)
                    Text(product.shades[item.shadeIndex].name).font(Theme.body(12))
                }
                .foregroundStyle(Theme.inkSecondary)
                Text(Product.formatPrice(product.price * Double(item.quantity))).font(Theme.body(14, .semibold))
            }
            .foregroundStyle(Theme.ink)
            Spacer()
            Stepper("Quantity", value: Binding(
                get: { item.quantity },
                set: { store.setQuantity($0, for: item) }
            ), in: 0...10)
            .labelsHidden()
        }
    }
}

struct OwnedProductsView: View {
    @Environment(AppStore.self) private var store
    @State private var editing = false

    var body: some View {
        ProductListScreen(
            title: "My Products",
            products: store.ownedProducts,
            empty: ("Nothing added yet", "Add products you already use for better matches.")
        )
        .toolbar {
            Button("Edit") { editing = true }
        }
        .sheet(isPresented: $editing) {
            TraitEditorSheet(trait: .products)
        }
    }
}

struct RecentProductsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ProductListScreen(
            title: "Recently Viewed",
            products: store.recentProducts,
            empty: ("No recent products", "Products you open will show up here.")
        )
    }
}

/// Simple list of product rows reused by My Products, Recent and Saved > See all.
struct ProductListScreen: View {
    @Environment(AppStore.self) private var store
    let title: String
    let products: [Product]
    let empty: (String, String)
    @State private var toast: String?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if products.isEmpty {
                    EmptyStateView(symbol: "sparkles", title: empty.0, message: empty.1)
                }
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
            .padding(20)
        }
        .appBackground()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
    }
}
