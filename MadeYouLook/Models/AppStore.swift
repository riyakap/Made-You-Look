import SwiftUI
import Observation

/// Single source of truth for the signed-in user, their quiz answers, saved items and bag.
/// Everything is persisted to UserDefaults so state survives relaunches.
@Observable
final class AppStore {
    enum Phase: String, Codable {
        case welcome, onboarding, signUp, main
    }

    enum Tab: Hashable {
        case home, explore, saved, profile
    }

    var phase: Phase = .welcome { didSet { save() } }
    var profile = UserProfile() { didSet { save() } }
    var savedProductIDs: [String] = [] { didSet { save() } }
    var savedLookIDs: [String] = [] { didSet { save() } }
    var savedTutorialIDs: [String] = [] { didSet { save() } }
    var bag: [BagItem] = [] { didSet { save() } }
    var orders: [Order] = [] { didSet { save() } }
    var recentProductIDs: [String] = [] { didSet { save() } }
    var settings = AppSettings() { didSet { save() } }

    /// Not persisted: which tab is showing.
    var selectedTab: Tab = .home

    private static let storageKey = "MadeYouLook.state.v1"
    private var isLoading = false
    /// Turned off for debug screen launches so they never overwrite the real saved state.
    var persistenceEnabled = true

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-resetState") {
            UserDefaults.standard.removeObject(forKey: Self.storageKey)
        }
        #endif
        load()
    }

    // MARK: - Session

    func finishOnboarding() {
        phase = .signUp
    }

    func signUp(name: String, email: String, via provider: String? = nil) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        profile.name = trimmed.isEmpty ? "Beauty Lover" : trimmed
        profile.username = Self.username(from: profile.name)
        profile.email = email
        if provider == "Google" { settings.googleConnected = true }
        if provider == "Apple" { settings.appleConnected = true }
        selectedTab = .home
        phase = .main
    }

    /// "Sign In" is mocked: it loads the demo account from the Figma prototype.
    func signInDemo() {
        profile = UserProfile(
            name: "Asmitha",
            username: "asmithachunchu",
            email: "asmitha@uci.edu",
            goals: [.findMakeup, .inspiration],
            skinTone: .tan,
            skinType: .combination,
            budget: .midRange,
            looks: [.natural, .softGlam],
            concerns: [.acne, .darkCircles, .unevenTone],
            ownedProductIDs: ["rare-soft-pinch", "mario-surrealskin", "elf-halo-glow"]
        )
        savedProductIDs = ["elf-halo-glow", "rare-soft-pinch", "mario-surrealskin"]
        savedLookIDs = ["everyday-glow", "date-night"]
        savedTutorialIDs = ["everyday-natural", "bronzed-summer"]
        selectedTab = .home
        phase = .main
    }

    /// "Sign In" on the welcome screen: resume the saved account if there is one,
    /// otherwise load the demo account. (Sign-in is mocked; there is no password.)
    func signIn() {
        if hasAccount {
            selectedTab = .home
            phase = .main
        } else {
            signInDemo()
        }
    }

    var hasAccount: Bool { !profile.name.isEmpty }

    /// "Get Started" begins a fresh account through the quiz.
    func startOnboarding() {
        clearUserData()
        phase = .onboarding
    }

    func logOut() {
        clearUserData()
        phase = .welcome
    }

    private func clearUserData() {
        profile = UserProfile()
        savedProductIDs = []
        savedLookIDs = []
        savedTutorialIDs = []
        bag = []
        orders = []
        recentProductIDs = []
        settings = AppSettings()
        selectedTab = .home
    }

    private static func username(from name: String) -> String {
        let cleaned = name.lowercased().filter { $0.isLetter || $0.isNumber }
        return cleaned.isEmpty ? "beautylover" : cleaned
    }

    // MARK: - Saved

    func isSaved(product id: String) -> Bool { savedProductIDs.contains(id) }
    func isSaved(look id: String) -> Bool { savedLookIDs.contains(id) }
    func isSaved(tutorial id: String) -> Bool { savedTutorialIDs.contains(id) }

    func toggleSaved(product id: String) { toggle(id, in: &savedProductIDs) }
    func toggleSaved(look id: String) { toggle(id, in: &savedLookIDs) }
    func toggleSaved(tutorial id: String) { toggle(id, in: &savedTutorialIDs) }

    private func toggle(_ id: String, in list: inout [String]) {
        if let index = list.firstIndex(of: id) {
            list.remove(at: index)
        } else {
            list.insert(id, at: 0)
            SoundEffects.shared.play(.save)
        }
    }

    var savedProducts: [Product] { savedProductIDs.compactMap(Catalog.product) }
    var savedLooks: [Look] { savedLookIDs.compactMap(Catalog.look) }
    var savedTutorials: [Look] { savedTutorialIDs.compactMap(Catalog.look) }
    var savedCount: Int { savedProductIDs.count + savedLookIDs.count + savedTutorialIDs.count }

    // MARK: - Bag

    var bagCount: Int { bag.reduce(0) { $0 + $1.quantity } }

    var bagSubtotal: Double {
        bag.reduce(0) { total, item in
            total + (Catalog.product(item.productID)?.price ?? 0) * Double(item.quantity)
        }
    }

    func addToBag(_ product: Product, shadeIndex: Int? = nil, quantity: Int = 1) {
        let shade = shadeIndex ?? recommendedShadeIndex(for: product)
        if let index = bag.firstIndex(where: { $0.productID == product.id && $0.shadeIndex == shade }) {
            bag[index].quantity += quantity
        } else {
            bag.append(BagItem(productID: product.id, shadeIndex: shade, quantity: quantity))
        }
        SoundEffects.shared.play(.addToBag)
    }

    func setQuantity(_ quantity: Int, for item: BagItem) {
        guard let index = bag.firstIndex(where: { $0.id == item.id }) else { return }
        if quantity <= 0 {
            bag.remove(at: index)
        } else {
            bag[index].quantity = quantity
        }
    }

    // MARK: - Checkout

    /// Shipping is free on bags of $35 or more.
    static let freeShippingThreshold = 35.0
    static let flatShipping = 4.95

    /// The 10% welcome offer from the sign-up screen applies to the first order only.
    var qualifiesForFirstOrderDiscount: Bool { orders.isEmpty }

    var bagDiscount: Double {
        qualifiesForFirstOrderDiscount ? (bagSubtotal * 0.10 * 100).rounded() / 100 : 0
    }

    var bagShipping: Double {
        bag.isEmpty || bagSubtotal >= Self.freeShippingThreshold ? 0 : Self.flatShipping
    }

    var bagTotal: Double { bagSubtotal - bagDiscount + bagShipping }

    /// Turns the bag into an order and empties the bag. Checkout is simulated: no payment is taken.
    @discardableResult
    func placeOrder(shipToName: String, shipToAddress: String, paymentSummary: String) -> Order? {
        let lines: [OrderLine] = bag.compactMap { item in
            guard let product = Catalog.product(item.productID) else { return nil }
            let shade = product.shades.indices.contains(item.shadeIndex)
                ? product.shades[item.shadeIndex] : product.shades[0]
            return OrderLine(productID: product.id, brand: product.brand, name: product.cardName,
                             shadeName: shade.name, unitPrice: product.price, quantity: item.quantity)
        }
        guard !lines.isEmpty else { return nil }

        // Work out the money before the bag is emptied and orders changes.
        let order = Order(
            number: "MYL-\(Int.random(in: 100_000...999_999))",
            date: Date(),
            lines: lines,
            subtotal: bagSubtotal,
            discount: bagDiscount,
            shipping: bagShipping,
            total: bagTotal,
            shipToName: shipToName,
            shipToAddress: shipToAddress,
            paymentSummary: paymentSummary
        )
        orders.insert(order, at: 0)
        bag = []
        SoundEffects.shared.play(.addToBag)
        return order
    }

    // MARK: - Owned products & recents

    var ownedProducts: [Product] {
        Catalog.products.filter { profile.ownedProductIDs.contains($0.id) }
    }

    var recentProducts: [Product] { recentProductIDs.compactMap(Catalog.product) }

    func markViewed(_ product: Product) {
        recentProductIDs.removeAll { $0 == product.id }
        recentProductIDs.insert(product.id, at: 0)
        if recentProductIDs.count > 24 { recentProductIDs.removeLast() }
    }

    var favoriteBrands: [String] {
        var seen = Set<String>()
        return ownedProducts.map(\.brand).filter { seen.insert($0).inserted }
    }

    // MARK: - Personalization

    /// Research-based score and reasons for one product (see Personalization.swift / research.json).
    func match(for product: Product) -> ProductMatch {
        let base = Personalizer.match(product, for: profile, favoriteBrands: favoriteBrands)
        // The catalog's own concern tags break ties between equally good matches.
        let tieBreak = product.concerns.intersection(profile.concerns).count
        return ProductMatch(product: product, score: base.score * 10 + tieBreak, reasons: base.reasons)
    }

    /// The single most relevant reason, shown on product cards.
    func topReason(for product: Product) -> String? {
        match(for: product).reasons.first
    }

    /// Products ranked for this user; products they already own go last.
    var recommendedProducts: [Product] {
        let scores = Dictionary(uniqueKeysWithValues: Catalog.products.map { ($0.id, match(for: $0).score) })
        return Catalog.products.sorted { a, b in
            let aOwned = profile.ownedProductIDs.contains(a.id)
            let bOwned = profile.ownedProductIDs.contains(b.id)
            if aOwned != bOwned { return !aOwned }
            let (sa, sb) = (scores[a.id] ?? 0, scores[b.id] ?? 0)
            if sa != sb { return sa > sb }
            return a.rating > b.rating
        }
    }

    var recommendedLooks: [Look] {
        Catalog.looks.sorted { a, b in
            let sa = lookScore(a), sb = lookScore(b)
            if sa != sb { return sa > sb }
            return a.minutes < b.minutes
        }
    }

    private func lookScore(_ look: Look) -> Int {
        var score = look.styles.intersection(profile.looks).count * 3
        if let tone = profile.skinTone, look.tones.contains(tone) { score += 2 }
        if profile.goals.contains(.learnLooks), look.difficulty == "Easy" { score += 1 }
        return score
    }

    func lookReason(for look: Look) -> String? {
        if let style = LookStyle.allCases.first(where: { look.styles.contains($0) && profile.looks.contains($0) }) {
            return "Matches your \(style.title) pick"
        }
        if profile.goals.contains(.learnLooks), look.difficulty == "Easy" { return "Easy to learn" }
        return nil
    }

    func shadeSuggestion(for product: Product) -> ShadeSuggestion? {
        profile.skinTone.flatMap { Personalizer.suggestedShade(for: product, tone: $0) }
    }

    func recommendedShadeIndex(for product: Product) -> Int {
        shadeSuggestion(for: product)?.index ?? 0
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var phase: Phase
        var profile: UserProfile
        var savedProductIDs: [String]
        var savedLookIDs: [String]
        var savedTutorialIDs: [String]
        var bag: [BagItem]
        /// Optional so state saved before orders existed still loads.
        var orders: [Order]?
        var recentProductIDs: [String]
        var settings: AppSettings
    }

    private func save() {
        guard !isLoading, persistenceEnabled else { return }
        let snapshot = Snapshot(
            phase: phase, profile: profile, savedProductIDs: savedProductIDs,
            savedLookIDs: savedLookIDs, savedTutorialIDs: savedTutorialIDs, bag: bag,
            orders: orders, recentProductIDs: recentProductIDs, settings: settings
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        isLoading = true
        defer { isLoading = false }
        // Every launch starts on the welcome screen, matching the prototype's "Initial Launch".
        phase = .welcome
        profile = snapshot.profile
        savedProductIDs = snapshot.savedProductIDs
        savedLookIDs = snapshot.savedLookIDs
        savedTutorialIDs = snapshot.savedTutorialIDs
        bag = snapshot.bag
        orders = snapshot.orders ?? []
        recentProductIDs = snapshot.recentProductIDs
        settings = snapshot.settings
    }
}
