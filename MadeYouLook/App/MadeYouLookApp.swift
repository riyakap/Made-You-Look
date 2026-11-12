import SwiftUI

@main
struct MadeYouLookApp: App {
    @State private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .tint(Theme.primary)
                .preferredColorScheme(.light)
                #if targetEnvironment(macCatalyst)
                .onAppear(perform: lockPhoneSizedWindow)
                #endif
        }
    }

    #if targetEnvironment(macCatalyst)
    /// The layout is designed for iPhone, so the Mac window keeps a phone shape.
    private func lockPhoneSizedWindow() {
        let size = CGSize(width: 402, height: 874)
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            scene.sizeRestrictions?.minimumSize = size
            scene.sizeRestrictions?.maximumSize = size
            scene.titlebar?.titleVisibility = .hidden
        }
    }
    #endif
}

struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        #if DEBUG
        if let screen = UserDefaults.standard.string(forKey: "uiScreen") {
            DebugScreen(name: screen)
        } else {
            content
        }
        #else
        content
        #endif
    }

    private var content: some View {
        Group {
            switch store.phase {
            case .welcome: WelcomeView()
            case .onboarding: OnboardingFlow()
            case .signUp: AllSetView()
            case .main: MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.phase)
    }
}

/// Destinations pushed inside each tab's NavigationStack.
enum Route: Hashable {
    case product(String)
    case look(String)
    case recommendations
    case bag
    case orders
    case ownedProducts
    case recent
    case savedList(SavedListKind)
    case settings
}

enum SavedListKind: String, Hashable {
    case products, looks, tutorials

    var title: String { rawValue.capitalized }
}

extension View {
    func withRoutes() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .product(let id):
                if let product = Catalog.product(id) { ProductDetailView(product: product) }
            case .look(let id):
                if let look = Catalog.look(id) { LookDetailView(look: look) }
            case .recommendations: RecommendationsView()
            case .bag: BagView()
            case .orders: OrdersView()
            case .ownedProducts: OwnedProductsView()
            case .recent: RecentProductsView()
            case .savedList(let kind): SavedListView(kind: kind)
            case .settings: SettingsView()
            }
        }
    }
}

struct MainTabView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store
        TabView(selection: $store.selectedTab) {
            NavigationStack { HomeView().withRoutes() }
                .tabItem { Label("Home", systemImage: "house") }
                .tag(AppStore.Tab.home)
            NavigationStack { ExploreView().withRoutes() }
                .tabItem { Label("Explore", systemImage: "safari") }
                .tag(AppStore.Tab.explore)
            NavigationStack { SavedView().withRoutes() }
                .tabItem { Label("Saved", systemImage: "heart") }
                .tag(AppStore.Tab.saved)
            NavigationStack { ProfileView().withRoutes() }
                .tabItem { Label("Profile", systemImage: "person") }
                .tag(AppStore.Tab.profile)
        }
        .environment(\.symbolVariants, .none)
        .toolbarBackground(Theme.tabBar, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
