import SwiftUI

/// "Your Personalized Recommendations" list with category chips.
struct RecommendationsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var category: ProductCategory?
    @State private var toast: String?

    private var products: [Product] {
        store.recommendedProducts.filter { category == nil || $0.category == category }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 12) {
                    BackButton { dismiss() }
                    Text("Your Personalized\nRecommendations")
                        .font(Theme.display(30))
                        .foregroundStyle(Theme.ink)
                }
                .padding(.horizontal, 20)

                ChipBar(items: [nil] + ProductCategory.allCases.map(Optional.some), selection: $category) {
                    $0?.title ?? "All"
                }

                LazyVStack(spacing: 14) {
                    ForEach(products) { product in
                        NavigationLink(value: Route.product(product.id)) {
                            ProductRow(product: product) {
                                store.addToBag(product)
                                toast = "Added \(product.cardName) to bag"
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    if products.isEmpty {
                        EmptyStateView(symbol: "sparkles", title: "Nothing here yet", message: "Try another category.")
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 8)
        }
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
        .toast($toast)
    }
}
