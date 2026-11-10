import Foundation

// MARK: - Research data (Data/research.json)

/// The research behind recommendations: cited sources, attribute rules and shade guides.
struct Research: Decodable {
    struct Source: Decodable, Identifiable {
        let id: String
        let title: String
        let publisher: String
        let url: URL
        let kind: String
        let finding: String
    }

    /// "If the user has X, favor products with traits Y (and avoid Z)."
    struct Rule: Decodable, Identifiable {
        let id: String
        let title: String
        var skinTypes: [SkinType] = []
        var concerns: [Concern] = []
        /// Limits the rule to some categories (e.g. dark-circle coverage only applies to Face).
        var categories: [ProductCategory]? = nil
        let prefer: [ProductAttribute]
        var avoid: [ProductAttribute] = []
        let reason: String
        let explanation: String
        let sources: [String]

        enum CodingKeys: String, CodingKey {
            case id, title, skinTypes, concerns, categories, prefer, avoid, reason, explanation, sources
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(String.self, forKey: .id)
            title = try c.decode(String.self, forKey: .title)
            skinTypes = try c.decodeIfPresent([SkinType].self, forKey: .skinTypes) ?? []
            concerns = try c.decodeIfPresent([Concern].self, forKey: .concerns) ?? []
            categories = try c.decodeIfPresent([ProductCategory].self, forKey: .categories)
            prefer = try c.decode([ProductAttribute].self, forKey: .prefer)
            avoid = try c.decodeIfPresent([ProductAttribute].self, forKey: .avoid) ?? []
            reason = try c.decode(String.self, forKey: .reason)
            explanation = try c.decode(String.self, forKey: .explanation)
            sources = try c.decode([String].self, forKey: .sources)
        }

        func applies(to profile: UserProfile) -> Bool {
            if let type = profile.skinType, skinTypes.contains(type) { return true }
            return !profile.concerns.isDisjoint(with: concerns)
        }

        func covers(_ category: ProductCategory) -> Bool {
            categories?.contains(category) ?? true
        }
    }

    struct ToneGuide: Decodable {
        /// Acceptable shade lightness (0 = black, 1 = white) for this skin tone.
        let range: [Double]
        let advice: String
    }

    struct ShadeGuide: Decodable {
        let sources: [String]
        var tones: [String: ToneGuide]? = nil
        /// Bronzer: how much darker than the skin tone (lightness units).
        var offset: [Double]? = nil
        var advice: String? = nil
    }

    let updated: String
    let sources: [Source]
    let rules: [Rule]
    let shadeGuides: [String: ShadeGuide]

    func source(_ id: String) -> Source? { sources.first { $0.id == id } }

    static let shared: Research = {
        guard let url = Bundle.main.url(forResource: "research", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            assertionFailure("research.json missing from bundle")
            return Research(updated: "", sources: [], rules: [], shadeGuides: [:])
        }
        do {
            return try JSONDecoder().decode(Research.self, from: data)
        } catch {
            assertionFailure("research.json is invalid: \(error)")
            return Research(updated: "", sources: [], rules: [], shadeGuides: [:])
        }
    }()
}

// MARK: - Recommendations

/// A product scored for one user, with the human-readable reasons behind the score.
struct ProductMatch {
    let product: Product
    let score: Int
    let reasons: [String]
}

/// A suggested shade and why.
struct ShadeSuggestion {
    let index: Int
    let advice: String
}

enum Personalizer {
    static let ruleMatchWeight = 3
    static let ruleConflictPenalty = 4
    static let budgetWeight = 3
    static let styleWeight = 2
    static let shadeWeight = 2
    /// How far (in lightness) a foundation shade may be from the skin-tone reference to count as a match.
    static let complexionTolerance = 0.07

    static func match(_ product: Product, for profile: UserProfile, favoriteBrands: [String] = []) -> ProductMatch {
        var score = 0
        var reasons: [String] = []

        for rule in Research.shared.rules where rule.applies(to: profile) && rule.covers(product.category) {
            if !product.attributes.isDisjoint(with: rule.prefer) {
                score += ruleMatchWeight
                reasons.append(rule.reason)
            }
            if !product.attributes.isDisjoint(with: rule.avoid) {
                score -= ruleConflictPenalty
            }
        }

        if let tone = profile.skinTone, let suggestion = suggestedShade(for: product, tone: tone), suggestion.advice.isEmpty == false {
            score += shadeWeight
            reasons.append(kind(of: product) == .complexion
                           ? "Comes in a shade matched to your skin tone"
                           : "Has a shade suited to \(tone.title.lowercased()) skin")
        }

        if let budget = profile.budget, budget != .any {
            if budget.contains(product.price) {
                score += budgetWeight
                reasons.append("Fits your \(budget.title.lowercased()) budget")
            } else {
                score -= budgetWeight
            }
        }

        let sharedStyles = LookStyle.allCases.filter { product.styles.contains($0) && profile.looks.contains($0) }
        if let first = sharedStyles.first {
            score += sharedStyles.count * styleWeight
            reasons.append("Matches your \(first.title) style")
        }

        if favoriteBrands.contains(product.brand) { score += 1 }

        return ProductMatch(product: product, score: score, reasons: reasons)
    }

    // MARK: Shades

    /// Perceived lightness of a shade, 0 (black) ... 1 (white).
    static func lightness(_ hex: String) -> Double {
        let value = UInt32(hex, radix: 16) ?? 0
        let r = Double((value >> 16) & 0xFF), g = Double((value >> 8) & 0xFF), b = Double(value & 0xFF)
        return (0.299 * r + 0.587 * g + 0.114 * b) / 255
    }

    /// Skin-tone reference colors (same as the quiz swatches).
    static let toneHex: [SkinTone: String] = [
        .fair: "F1D3C2", .light: "E5BB9E", .lightMedium: "D3A07D", .tan: "B47A55", .deep: "7C4A30", .deepDark: "4A2C1F",
    ]

    enum ShadeKind { case complexion, blush, bronzer, lips, none }

    static func kind(of product: Product) -> ShadeKind {
        let name = product.name.lowercased()
        if product.category == .cheeks, name.contains("bronz") { return .bronzer }
        if product.shades.contains(where: { $0.tone != nil }) { return .complexion }
        switch product.category {
        case .cheeks:
            if name.contains("bronz") { return .bronzer }
            if name.range(of: "highlight|luminiz|light wand|glotion|killawatt", options: .regularExpression) != nil { return .none }
            return .blush
        case .lips:
            return product.shades.count > 1 ? .lips : .none
        default:
            return .none
        }
    }

    /// The best shade for a skin tone, with research-based advice (empty advice when we only fall back to the default).
    static func suggestedShade(for product: Product, tone: SkinTone) -> ShadeSuggestion? {
        let guides = Research.shared.shadeGuides
        switch kind(of: product) {
        case .complexion:
            // Compare actual shade lightness with the skin-tone reference rather than trusting
            // per-product rank labels, so a light-skewed range can't claim a match for deep skin.
            guard let target = toneHex[tone].map(lightness) else { return nil }
            let best = product.shades.indices.min { abs(lightness(product.shades[$0].hex) - target) < abs(lightness(product.shades[$1].hex) - target) }
            guard let index = best, abs(lightness(product.shades[index].hex) - target) <= complexionTolerance else { return nil }
            return ShadeSuggestion(index: index, advice: "Closest shade to your \(tone.title.lowercased()) skin tone.")
        case .blush:
            guard let guide = guides["blush"]?.tones?[tone.rawValue] else { return nil }
            return closest(in: product, to: guide.range, advice: guide.advice)
        case .lips:
            guard let guide = guides["lips"]?.tones?[tone.rawValue] else { return nil }
            return closest(in: product, to: guide.range, advice: guide.advice)
        case .bronzer:
            guard let bronzer = guides["bronzer"], let offset = bronzer.offset, offset.count == 2,
                  let skin = toneHex[tone].map(lightness) else { return nil }
            return closest(in: product, to: [skin - offset[1], skin - offset[0]], advice: bronzer.advice ?? "")
        case .none:
            return nil
        }
    }

    /// Picks the shade closest to a lightness range; nil if none is reasonably close.
    private static func closest(in product: Product, to range: [Double], advice: String) -> ShadeSuggestion? {
        guard range.count == 2, product.shades.count > 1 else { return nil }
        let (low, high) = (range[0], range[1])
        let center = (low + high) / 2
        let scored = product.shades.enumerated().map { index, shade -> (Int, Double) in
            let l = lightness(shade.hex)
            let outside = l < low ? low - l : (l > high ? l - high : 0)
            return (index, outside * 10 + abs(l - center))
        }
        guard let best = scored.min(by: { $0.1 < $1.1 }) else { return nil }
        // More than ~0.1 outside the range means nothing in this product really suits the tone.
        let l = lightness(product.shades[best.0].hex)
        let distance = l < low ? low - l : (l > high ? l - high : 0)
        return distance <= 0.1 ? ShadeSuggestion(index: best.0, advice: advice) : nil
    }
}
