import SwiftUI

// MARK: - Onboarding answers

enum Goal: String, Codable, CaseIterable, Identifiable {
    case findMakeup, inspiration, learnLooks, discover

    var id: String { rawValue }

    var title: String {
        switch self {
        case .findMakeup: "Find makeup made for me"
        case .inspiration: "Get makeup inspiration"
        case .learnLooks: "Learn how to create looks"
        case .discover: "Discover new products"
        }
    }

    var imageName: String {
        switch self {
        case .findMakeup: "goal_find_makeup"
        case .inspiration: "goal_inspiration"
        case .learnLooks: "goal_learn_looks"
        case .discover: "goal_discover"
        }
    }

    var symbol: String {
        switch self {
        case .findMakeup: "wand.and.stars"
        case .inspiration: "sparkles"
        case .learnLooks: "paintbrush.pointed"
        case .discover: "bag"
        }
    }
}

enum SkinTone: String, Codable, CaseIterable, Identifiable {
    case fair, light, lightMedium, tan, deep, deepDark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fair: "Fair"
        case .light: "Light"
        case .lightMedium: "Light Medium"
        case .tan: "Tan"
        case .deep: "Deep"
        case .deepDark: "Deep Dark"
        }
    }

    var imageName: String {
        switch self {
        case .fair: "tone_fair"
        case .light: "tone_light"
        case .lightMedium: "tone_light_medium"
        case .tan: "tone_tan"
        case .deep: "tone_deep"
        case .deepDark: "tone_deep_dark"
        }
    }

    var swatch: Color {
        switch self {
        case .fair: Color(hex: 0xF1D3C2)
        case .light: Color(hex: 0xE5BB9E)
        case .lightMedium: Color(hex: 0xD3A07D)
        case .tan: Color(hex: 0xB47A55)
        case .deep: Color(hex: 0x7C4A30)
        case .deepDark: Color(hex: 0x4A2C1F)
        }
    }
}

enum LookStyle: String, Codable, CaseIterable, Identifiable {
    case natural, bronzy, softGlam, fullGlam, dark, light

    var id: String { rawValue }

    var title: String {
        switch self {
        case .natural: "Natural"
        case .bronzy: "Bronzy"
        case .softGlam: "Soft Glam"
        case .fullGlam: "Full Glam"
        case .dark: "Dark Look"
        case .light: "Light Look"
        }
    }

    /// Shorter label used for filter chips.
    var chipTitle: String {
        switch self {
        case .dark: "Dark"
        case .light: "Light"
        default: title
        }
    }

    var imageName: String {
        switch self {
        case .natural: "style_natural"
        case .bronzy: "style_bronzy"
        case .softGlam: "style_soft_glam"
        case .fullGlam: "style_full_glam"
        case .dark: "style_dark"
        case .light: "style_light"
        }
    }
}

enum Concern: String, Codable, CaseIterable, Identifiable {
    case acne, darkCircles, redness, unevenTone, fineLines, dryness, oily, texture

    var id: String { rawValue }

    var title: String {
        switch self {
        case .acne: "Acne / Blemishes"
        case .darkCircles: "Dark Circles"
        case .redness: "Redness"
        case .unevenTone: "Uneven Skin Tone"
        case .fineLines: "Fine Lines"
        case .dryness: "Dryness"
        case .oily: "Oily Skin"
        case .texture: "Texture / Pores"
        }
    }

    /// Compact label for the profile summary row.
    var shortTitle: String {
        switch self {
        case .acne: "Acne"
        case .unevenTone: "Uneven Skin Tone"
        case .texture: "Texture"
        default: title
        }
    }

    var symbol: String {
        switch self {
        case .acne: "face.smiling"
        case .darkCircles: "eye"
        case .redness: "circle.hexagongrid.fill"
        case .unevenTone: "circle.fill"
        case .fineLines: "line.3.horizontal"
        case .dryness: "drop.triangle"
        case .oily: "drop"
        case .texture: "square.grid.3x3.square"
        }
    }
}

enum SkinType: String, Codable, CaseIterable, Identifiable {
    case oily, dry, combination, normal, sensitive

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    /// Quick self-check shown in the quiz.
    var hint: String {
        switch self {
        case .oily: "Shiny by midday, visible pores"
        case .dry: "Feels tight, rough or flaky"
        case .combination: "Oily T-zone, normal or dry cheeks"
        case .normal: "Comfortable, rarely oily or dry"
        case .sensitive: "Easily irritated, stings or turns red"
        }
    }

    var symbol: String {
        switch self {
        case .oily: "drop.fill"
        case .dry: "sun.dust"
        case .combination: "circle.lefthalf.filled"
        case .normal: "face.smiling"
        case .sensitive: "exclamationmark.shield"
        }
    }
}

enum Budget: String, Codable, CaseIterable, Identifiable {
    case drugstore, midRange, luxury, any

    var id: String { rawValue }

    var title: String {
        switch self {
        case .drugstore: "Drugstore"
        case .midRange: "Mid-range"
        case .luxury: "Luxury"
        case .any: "No preference"
        }
    }

    var hint: String {
        switch self {
        case .drugstore: "Under $20"
        case .midRange: "$20 – $35"
        case .luxury: "$35 and up"
        case .any: "Show me everything"
        }
    }

    var symbol: String {
        switch self {
        case .drugstore: "dollarsign"
        case .midRange: "dollarsign.circle"
        case .luxury: "crown"
        case .any: "infinity"
        }
    }

    func contains(_ price: Double) -> Bool {
        switch self {
        case .drugstore: price < 20
        case .midRange: price >= 20 && price <= 35
        case .luxury: price > 35
        case .any: true
        }
    }
}

/// Formula traits used by the research-based recommendation rules (see research.json).
enum ProductAttribute: String, Codable, CaseIterable {
    case matte, luminous, hydrating, oilFree, nonComedogenic, fragranceFree, mineral, spf
    case blurring, oilControl, longWear, waterproof, buildable, brightening, colorCorrecting, cream, powder

    var title: String {
        switch self {
        case .matte: "Matte"
        case .luminous: "Luminous"
        case .hydrating: "Hydrating"
        case .oilFree: "Oil-free"
        case .nonComedogenic: "Non-comedogenic"
        case .fragranceFree: "Fragrance-free"
        case .mineral: "Mineral"
        case .spf: "SPF"
        case .blurring: "Blurring"
        case .oilControl: "Oil control"
        case .longWear: "Long-wear"
        case .waterproof: "Waterproof"
        case .buildable: "Buildable"
        case .brightening: "Brightening"
        case .colorCorrecting: "Color-correcting"
        case .cream: "Cream / liquid"
        case .powder: "Powder"
        }
    }
}

// MARK: - Catalog

enum ProductCategory: String, CaseIterable, Identifiable, Codable {
    case face, cheeks, eyes, lips

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct Shade: Hashable, Codable {
    let name: String
    let detail: String
    /// Hex color without "#", e.g. "A85F69".
    let hex: String
    /// Complexion shades are matched to a skin tone; color shades leave this nil.
    var tone: SkinTone? = nil

    var color: Color { Color(hex: UInt32(hex, radix: 16) ?? 0xB86F79) }
}

/// One catalog entry, decoded from `products.json`.
struct Product: Identifiable, Hashable, Codable {
    let id: String
    let brand: String
    let name: String
    /// Name as written on small cards (the Figma uses a shorter name there).
    let cardName: String
    let category: ProductCategory
    let price: Double
    let rating: Double
    let reviewCount: Int
    let imageName: String
    var symbol: String = "sparkles"
    let shades: [Shade]
    var concerns: Set<Concern> = []
    var styles: Set<LookStyle> = []
    var attributes: Set<ProductAttribute> = []
    let details: String
    let howToUse: String
    /// Where the product data came from (retailer or brand page).
    var source: String? = nil
    /// Optional overrides from products.json (see ProductGuide.swift for the defaults).
    var buyURL: String? = nil
    var videoURL: String? = nil
    var steps: [String] = []

    var priceText: String { Self.formatPrice(price) }

    enum CodingKeys: String, CodingKey {
        case id, brand, name, cardName, category, price, rating, reviewCount, imageName, symbol
        case shades, concerns, styles, attributes, details, howToUse, source
        case buyURL, videoURL, steps
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        brand = try c.decode(String.self, forKey: .brand)
        name = try c.decode(String.self, forKey: .name)
        cardName = try c.decodeIfPresent(String.self, forKey: .cardName) ?? name
        category = try c.decode(ProductCategory.self, forKey: .category)
        price = try c.decode(Double.self, forKey: .price)
        rating = try c.decodeIfPresent(Double.self, forKey: .rating) ?? 0
        reviewCount = try c.decodeIfPresent(Int.self, forKey: .reviewCount) ?? 0
        imageName = try c.decodeIfPresent(String.self, forKey: .imageName) ?? "product_\(id)"
        symbol = try c.decodeIfPresent(String.self, forKey: .symbol) ?? "sparkles"
        // Screens index into shades, so always have at least one.
        let decodedShades = try c.decodeIfPresent([Shade].self, forKey: .shades) ?? []
        shades = decodedShades.isEmpty ? [Shade(name: "Standard", detail: "One shade", hex: "B86F79")] : decodedShades
        concerns = try c.decodeIfPresent(Set<Concern>.self, forKey: .concerns) ?? []
        styles = try c.decodeIfPresent(Set<LookStyle>.self, forKey: .styles) ?? []
        attributes = try c.decodeIfPresent(Set<ProductAttribute>.self, forKey: .attributes) ?? []
        details = try c.decodeIfPresent(String.self, forKey: .details) ?? ""
        howToUse = try c.decodeIfPresent(String.self, forKey: .howToUse) ?? ""
        source = try c.decodeIfPresent(String.self, forKey: .source)
        buyURL = try c.decodeIfPresent(String.self, forKey: .buyURL)
        videoURL = try c.decodeIfPresent(String.self, forKey: .videoURL)
        steps = try c.decodeIfPresent([String].self, forKey: .steps) ?? []
    }

    var reviews: String {
        reviewCount >= 1000
            ? String(format: "%.1fk", Double(reviewCount) / 1000).replacingOccurrences(of: ".0k", with: "k")
            : "\(reviewCount)"
    }

    static func formatPrice(_ value: Double) -> String {
        value.rounded() == value ? "$\(Int(value))" : String(format: "$%.2f", value)
    }
}

struct Look: Identifiable, Hashable {
    let id: String
    let title: String
    let styles: Set<LookStyle>
    let minutes: Int
    let difficulty: String
    let imageName: String
    let productIDs: [String]
    let summary: String
    let tones: Set<SkinTone>

    var meta: String { "\(minutes) min • \(difficulty)" }
}

// MARK: - User data

struct UserProfile: Codable, Equatable {
    var name = ""
    var username = ""
    var email = ""
    var avatarData: Data?

    var goals: Set<Goal> = []
    var skinTone: SkinTone?
    var skinType: SkinType?
    var budget: Budget?
    var looks: Set<LookStyle> = []
    var concerns: Set<Concern> = []
    var ownedProductIDs: Set<String> = []
}

struct BagItem: Codable, Identifiable, Equatable {
    var id = UUID()
    let productID: String
    var shadeIndex: Int
    var quantity: Int
}

struct AppSettings: Codable, Equatable {
    var pushNotifications = true
    var newProductAlerts = true
    var emailUpdates = false
    var privateProfile = false
    var personalizedAds = false
    var googleConnected = false
    var appleConnected = false
}

struct AppNotification: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let message: String
    let time: String
}
