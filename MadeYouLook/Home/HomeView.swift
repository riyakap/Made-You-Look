import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store
    @State private var query = ""
    @State private var filters = SearchFilters()
    @State private var showingFilters = false
    @State private var showingNotifications = false

    private var isSearching: Bool { !query.isEmpty || filters.isActive }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                SearchField(
                    text: $query,
                    prompt: "Search products, brands, or looks...",
                    onFilter: { showingFilters = true },
                    filterActive: filters.isActive
                )
                .padding(.horizontal, 20)

                if isSearching {
                    SearchResultsView(query: query, filters: filters)
                } else {
                    banner
                    forYou
                    looksYoullLove
                }
            }
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.immediately)
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingFilters) {
            FilterSheet(filters: $filters)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsSheet()
                .presentationDetents([.medium])
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Text("made you look")
                .font(Theme.display(30))
                .foregroundStyle(Theme.ink)
            Spacer()
            Button { showingNotifications = true } label: {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.ink)
            }
            .accessibilityLabel("Notifications")
            Button { store.selectedTab = .profile } label: {
                AvatarView(data: store.profile.avatarData, size: 38)
            }
            .accessibilityLabel("Profile")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var banner: some View {
        ZStack(alignment: .leading) {
            AssetImage(name: "hero_products", symbol: "sparkles")
                .frame(height: 170)
                .frame(maxWidth: .infinity)
            LinearGradient(
                colors: [Theme.background.opacity(0.95), Theme.background.opacity(0.6), .clear],
                startPoint: .leading, endPoint: .trailing
            )
            VStack(alignment: .leading, spacing: 8) {
                Text("Products\nmade for you")
                    .font(Theme.display(26))
                    .foregroundStyle(Theme.ink)
                Text("Personalized recommendations\nbased on your style, skin, and goals.")
                    .font(Theme.body(12))
                    .foregroundStyle(Theme.ink.opacity(0.8))
                Button { store.selectedTab = .profile } label: {
                    HStack(spacing: 6) {
                        Text("View my profile")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(SmallPillButtonStyle())
                .padding(.top, 4)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private var forYou: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "For You", route: .recommendations)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(store.recommendedProducts.prefix(8)) { product in
                        NavigationLink(value: Route.product(product.id)) {
                            ProductTile(product: product, showsHeart: true, showsReason: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var looksYoullLove: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Looks You'll Love") { store.selectedTab = .explore }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.recommendedLooks.prefix(6)) { look in
                        NavigationLink(value: Route.look(look.id)) {
                            LookTile(look: look, showsHeart: true, width: 120, height: 150)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Search

struct SearchFilters: Equatable {
    var categories: Set<ProductCategory> = []
    var maxPrice: Double = SearchFilters.priceCeiling
    var styles: Set<LookStyle> = []
    var sort: Sort = .bestMatch

    enum Sort: String, CaseIterable, Identifiable {
        case bestMatch = "Best match"
        case priceLow = "Price: low to high"
        case priceHigh = "Price: high to low"
        case rating = "Top rated"

        var id: String { rawValue }
    }

    static let priceCeiling: Double = 70

    var isActive: Bool { self != SearchFilters() }
}

struct SearchResultsView: View {
    @Environment(AppStore.self) private var store
    let query: String
    let filters: SearchFilters

    private var products: [Product] {
        let matches = store.recommendedProducts.filter { product in
            (query.isEmpty || "\(product.brand) \(product.name) \(product.category.title)".localizedCaseInsensitiveContains(query))
            && (filters.categories.isEmpty || filters.categories.contains(product.category))
            && (filters.styles.isEmpty || !product.styles.isDisjoint(with: filters.styles))
            && (filters.maxPrice >= SearchFilters.priceCeiling || product.price <= filters.maxPrice)
        }
        switch filters.sort {
        case .bestMatch: return matches
        case .priceLow: return matches.sorted { $0.price < $1.price }
        case .priceHigh: return matches.sorted { $0.price > $1.price }
        case .rating: return matches.sorted { $0.rating > $1.rating }
        }
    }

    private var looks: [Look] {
        store.recommendedLooks.filter { look in
            (query.isEmpty || look.title.localizedCaseInsensitiveContains(query)
                || look.styles.contains { $0.title.localizedCaseInsensitiveContains(query) })
            && (filters.styles.isEmpty || !look.styles.isDisjoint(with: filters.styles))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if products.isEmpty && looks.isEmpty {
                EmptyStateView(symbol: "magnifyingglass", title: "No results", message: "Try a different search or loosen your filters.")
            }
            if !products.isEmpty {
                Text("Products (\(products.count))")
                    .font(Theme.display(20))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 20)
                ForEach(products) { product in
                    NavigationLink(value: Route.product(product.id)) {
                        ProductRow(product: product) { store.addToBag(product) }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                }
            }
            if !looks.isEmpty {
                Text("Looks (\(looks.count))")
                    .font(Theme.display(20))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(looks) { look in
                            NavigationLink(value: Route.look(look.id)) {
                                LookTile(look: look, width: 120, height: 150)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

struct FilterSheet: View {
    @Binding var filters: SearchFilters
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Sort by") {
                    Picker("Sort", selection: $filters.sort) {
                        ForEach(SearchFilters.Sort.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
                Section("Category") {
                    FlowChips(items: ProductCategory.allCases, isSelected: { filters.categories.contains($0) }, title: \.title) {
                        filters.categories.toggle($0)
                    }
                }
                Section("Look") {
                    FlowChips(items: LookStyle.allCases, isSelected: { filters.styles.contains($0) }, title: \.chipTitle) {
                        filters.styles.toggle($0)
                    }
                }
                Section(filters.maxPrice >= SearchFilters.priceCeiling ? "Max price: any" : "Max price: $\(Int(filters.maxPrice))") {
                    Slider(value: $filters.maxPrice, in: 10...SearchFilters.priceCeiling, step: 5)
                }
            }
            .scrollContentBackground(.hidden)
            .appBackground()
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") { filters = SearchFilters() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

/// Wrapping row of chips for multi-select filters.
struct FlowChips<Item: Hashable>: View {
    let items: [Item]
    let isSelected: (Item) -> Bool
    let title: KeyPath<Item, String>
    let toggle: (Item) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Chip(title: item[keyPath: title], isSelected: isSelected(item)) { toggle(item) }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct NotificationsSheet: View {
    var body: some View {
        NavigationStack {
            List(Catalog.notifications) { note in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: note.symbol)
                        .foregroundStyle(Theme.primary)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(note.title).font(Theme.body(15, .semibold))
                        Text(note.message).font(Theme.body(13)).foregroundStyle(Theme.inkSecondary)
                    }
                    Spacer()
                    Text(note.time).font(Theme.body(12)).foregroundStyle(Theme.inkSecondary)
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .appBackground()
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
