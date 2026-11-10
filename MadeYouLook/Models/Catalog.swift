import Foundation

/// Built-in product and look database. Products live in `products.json`; looks are defined below.
/// Image names map to bundled assets; any missing asset falls back to a styled placeholder.
enum Catalog {
    static func product(_ id: String) -> Product? { productsByID[id] }
    static func look(_ id: String) -> Look? { looksByID[id] }

    private static let productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
    private static let looksByID = Dictionary(uniqueKeysWithValues: looks.map { ($0.id, $0) })

    static var brands: [String] {
        var seen = Set<String>()
        return products.map(\.brand).filter { seen.insert($0).inserted }
    }

    // MARK: Products

    /// Loaded from `Data/products.json` in the app bundle. To add a product, add an entry there
    /// (and optionally an image named `imageName` in Assets.xcassets).
    static let products: [Product] = {
        guard let url = Bundle.main.url(forResource: "products", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            assertionFailure("products.json missing from bundle")
            return []
        }
        do {
            return try JSONDecoder().decode([Product].self, from: data)
        } catch {
            assertionFailure("products.json is invalid: \(error)")
            return []
        }
    }()

    // MARK: Looks

    static let looks: [Look] = [
        Look(
            id: "everyday-natural", title: "Everyday Natural Look", styles: [.natural, .light],
            minutes: 5, difficulty: "Easy", imageName: "look_everyday_natural",
            productIDs: ["elf-halo-glow", "rare-soft-pinch", "maybelline-sky-high", "fenty-gloss-bomb"],
            summary: "Skin-first and fresh: a glowy base, a pop of flush, and glossy lips.",
            tones: [.fair, .light, .lightMedium]
        ),
        Look(
            id: "bronzed-summer", title: "Bronzed Summer Look", styles: [.bronzy],
            minutes: 8, difficulty: "Medium", imageName: "look_bronzed_summer",
            productIDs: ["elf-halo-glow", "benefit-hoola", "huda-nude-palette", "fenty-gloss-bomb"],
            summary: "Warm, sun-kissed bronze from cheekbones to lids with a juicy lip.",
            tones: [.lightMedium, .tan, .deep]
        ),
        Look(
            id: "smoky-night", title: "Smoky Night Out", styles: [.dark, .fullGlam],
            minutes: 15, difficulty: "Hard", imageName: "look_smoky_night",
            productIDs: ["mario-surrealskin", "huda-nude-palette", "maybelline-sky-high", "ct-lip-cheat", "laura-mercier-powder"],
            summary: "A diffused smoky eye with sculpted skin and a defined lip.",
            tones: [.tan, .deep, .deepDark]
        ),
        Look(
            id: "everyday-glow", title: "Everyday Glow", styles: [.natural, .softGlam],
            minutes: 7, difficulty: "Easy", imageName: "look_everyday_glow",
            productIDs: ["la-roche-tinted", "mario-surrealskin", "glossier-cloud-paint", "fenty-gloss-bomb"],
            summary: "Even, radiant skin with soft color for days you want to look polished but effortless.",
            tones: [.lightMedium, .tan, .deep]
        ),
        Look(
            id: "date-night", title: "Date Night", styles: [.fullGlam, .softGlam],
            minutes: 12, difficulty: "Medium", imageName: "look_date_night",
            productIDs: ["nars-radiant-creamy", "benefit-hoola", "huda-nude-palette", "ct-lip-cheat"],
            summary: "Sculpted, glowing skin and a sultry eye for an evening out.",
            tones: [.deep, .deepDark, .tan]
        ),
        Look(
            id: "soft-glam-brunch", title: "Soft Glam Brunch", styles: [.softGlam],
            minutes: 10, difficulty: "Medium", imageName: "look_soft_glam_brunch",
            productIDs: ["mario-surrealskin", "rare-soft-pinch", "huda-nude-palette", "ct-lip-cheat"],
            summary: "Blurred skin, rosy cheeks and a neutral shimmer lid.",
            tones: [.fair, .light, .lightMedium, .tan]
        ),
        Look(
            id: "clean-girl", title: "Clean Girl Glow", styles: [.light, .natural],
            minutes: 4, difficulty: "Easy", imageName: "look_clean_girl",
            productIDs: ["la-roche-tinted", "glossier-cloud-paint", "fenty-gloss-bomb"],
            summary: "Minimal, dewy, and done in under five minutes.",
            tones: [.fair, .light]
        ),
        Look(
            id: "sunset-bronze", title: "Sunset Bronze Glam", styles: [.bronzy, .fullGlam],
            minutes: 14, difficulty: "Hard", imageName: "look_sunset_bronze",
            productIDs: ["nars-radiant-creamy", "benefit-hoola", "huda-nude-palette", "maybelline-sky-high", "laura-mercier-powder"],
            summary: "Warm terracotta eyes, bronzed cheeks and a glossy nude lip.",
            tones: [.tan, .deep, .deepDark]
        ),
    ]

    // MARK: Notifications

    static let notifications: [AppNotification] = [
        AppNotification(symbol: "sparkles", title: "New picks for you", message: "We found 3 new products that match your beauty profile.", time: "2h"),
        AppNotification(symbol: "tag.fill", title: "10% off your first order", message: "Your welcome discount is waiting in your bag.", time: "1d"),
        AppNotification(symbol: "play.circle.fill", title: "New tutorial", message: "Soft Glam Brunch: a 10-minute look for weekends.", time: "3d"),
    ]
}
