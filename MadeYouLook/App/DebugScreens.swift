#if DEBUG
import SwiftUI

/// Debug-only: launch with `-uiScreen <name>` to open a screen directly (used for screenshots).
struct DebugScreen: View {
    @Environment(AppStore.self) private var store
    let name: String
    @State private var ready = false

    var body: some View {
        Group {
            if ready { content } else { Color.clear }
        }
        .onAppear {
            store.persistenceEnabled = false
            if !name.hasPrefix("onboarding") && name != "welcome" && name != "allset" {
                store.signInDemo()
                if name == "bag", store.bag.isEmpty {
                    store.addToBag(Catalog.products[0])
                    store.addToBag(Catalog.products[1], quantity: 2)
                }
            }
            ready = true
        }
    }

    @ViewBuilder
    private var content: some View {
        switch name {
        case "welcome": WelcomeView()
        case "allset": AllSetView()
        case let s where s.hasPrefix("onboarding"): OnboardingFlow(initialStep: Int(s.dropFirst(10)) ?? 0)
        case "recs": NavigationStack { RecommendationsView().withRoutes() }
        case let s where s.hasPrefix("product"):
            // "product" or "product=<id>"
            let id = s.split(separator: "=").dropFirst().first.map(String.init)
            let product = id.flatMap(Catalog.product) ?? Catalog.products[0]
            NavigationStack { ProductDetailView(product: product).withRoutes() }
        case "look": NavigationStack { LookDetailView(look: Catalog.looks[0]).withRoutes() }
        case "settings": NavigationStack { SettingsView().withRoutes() }
        case "research": NavigationStack { ResearchView() }
        case "bag": NavigationStack { BagView().withRoutes() }
        case "explore", "saved", "profile", "home":
            MainTabView().onAppear {
                store.selectedTab = ["explore": .explore, "saved": .saved, "profile": .profile][name] ?? .home
            }
        default: MainTabView()
        }
    }
}
#endif
