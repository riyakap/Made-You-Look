import Foundation

// MARK: - Where to buy, how to apply

/// Buy link, YouTube link and written application steps for every product.
///
/// Nothing here needs new data: all 60 products get working defaults.
///   • Buy link:   `buyURL` if set in products.json, else the Sephora/Ulta page in `source`,
///                 else a Sephora search for the product.
///   • Video link: `videoURL` if set in products.json, else a YouTube search for the product.
///   • Steps:      `steps` if set in products.json, else the steps for the kind of product.
/// To make a product link to one specific video or page, add "videoURL" / "buyURL" / "steps"
/// to its entry in products.json.
extension Product {

    // MARK: Buy

    var buyLink: URL {
        if let buyURL, let url = URL(string: buyURL) { return url }
        if let url = retailerSourceURL { return url }
        return Self.url("https://www.sephora.com/search", ["keyword": "\(brand) \(name)"])
    }

    /// True when `buyLink` goes straight to the product page rather than to a search.
    var hasDirectBuyPage: Bool {
        (buyURL.flatMap { URL(string: $0) } != nil) || retailerSourceURL != nil
    }

    var retailerName: String {
        let host = buyLink.host?.lowercased() ?? ""
        if host.contains("ulta") { return "Ulta Beauty" }
        if host.contains("sephora") { return "Sephora" }
        return host.replacingOccurrences(of: "www.", with: "")
    }

    private var retailerSourceURL: URL? {
        guard let source, let url = URL(string: source), let host = url.host?.lowercased(),
              host.contains("sephora.com") || host.contains("ulta.com") else { return nil }
        return url
    }

    // MARK: Video

    var videoLink: URL {
        if let videoURL, let url = URL(string: videoURL) { return url }
        return Self.url("https://www.youtube.com/results",
                        ["search_query": "\(brand) \(name) how to apply tutorial"])
    }

    /// True when `videoLink` is one specific video rather than a YouTube search.
    var hasDirectVideo: Bool { videoURL.flatMap { URL(string: $0) } != nil }

    // MARK: Steps

    var tutorialSteps: [String] { steps.isEmpty ? TutorialKind(for: self).steps : steps }

    private static func url(_ base: String, _ query: [String: String]) -> URL {
        var components = URLComponents(string: base)!
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.url!
    }
}

/// The kind of product, worked out from its category and name. Each kind has its own steps.
enum TutorialKind {
    case foundation, concealer, primer, settingPowder, tintedSPF, glowFilter
    case creamBlush, powderBlush, bronzer, highlighter
    case mascara, eyeliner, brow, eyeshadowPalette
    case lipLiner, liquidLip, glossOrOil, lipBalm, lipMask

    init(for product: Product) {
        let name = product.name.lowercased()
        func has(_ words: String...) -> Bool { words.contains { name.contains($0) } }

        switch product.category {
        case .face:
            if has("primer") { self = .primer }
            else if has("powder") { self = .settingPowder }
            else if has("concealer", "shape tape", "eraser") { self = .concealer }
            else if has("foundation") { self = .foundation }
            else if has("anthelios", "tinted", "spf") { self = .tintedSPF }
            else if has("filter", "glow") { self = .glowFilter }
            else { self = .foundation }
        case .cheeks:
            if has("highlight", "luminizer", "wand", "glotion", "glow enhancer") { self = .highlighter }
            else if has("bronz") { self = .bronzer }
            else if has("powder blush") { self = .powderBlush }
            else { self = .creamBlush }
        case .eyes:
            if has("mascara") { self = .mascara }
            else if has("brow") { self = .brow }
            else if has("palette") { self = .eyeshadowPalette }
            else { self = .eyeliner }
        case .lips:
            if has("liner", "pencil") { self = .lipLiner }
            else if has("mask", "sleeping") { self = .lipMask }
            else if has("balm", "treatment") { self = .lipBalm }
            else if has("liquid lipstick", "lipcolor", "vinyl ink", "matte resistance") { self = .liquidLip }
            else { self = .glossOrOil }
        }
    }

    var steps: [String] {
        switch self {
        case .foundation: [
            "Start with clean, moisturized skin and let your skincare sink in for a minute.",
            "Dot a small amount on your forehead, cheeks, nose and chin. Start with less than you think you need.",
            "Blend outward from the center of the face with a damp sponge, a foundation brush or clean fingers.",
            "Tap and press along the sides of the nose and around the mouth so it melts into the skin.",
            "Build up coverage only where you want it, then set with a light dusting of powder if you like.",
        ]
        case .concealer: [
            "Apply your foundation or skin tint first, so you only cover what is left.",
            "Dot concealer under the eyes in a small triangle and on any blemishes or redness.",
            "Tap it in with a fingertip or damp sponge. Patting blends better than rubbing.",
            "Feather the edges outward so there is no visible line, then let it sit for a few seconds.",
            "Set with a little translucent powder if you crease or want it to last.",
        ]
        case .primer: [
            "Apply after moisturizer and sunscreen, on skin that is dry to the touch.",
            "Use a pea-sized amount for the whole face. Focus on the T-zone, nose and cheeks.",
            "Press it in with your fingertips, working from the center of the face outward.",
            "Wait about a minute until it feels tacky or smooth, then apply foundation.",
        ]
        case .settingPowder: [
            "Apply your base products first and make sure they are blended.",
            "Tap a fluffy brush or a velour puff into the powder and knock off the excess.",
            "Press it into the T-zone and under the eyes. Pressing keeps the base from moving.",
            "Sweep a light layer over the rest of the face.",
            "For long wear, let the powder sit for a minute or two, then brush off what is left.",
        ]
        case .tintedSPF: [
            "Finish your skincare, then use enough sunscreen to cover face and neck. About two finger lengths is the usual guide.",
            "Dot it over the face and blend in with your fingers until the color evens out.",
            "Do not forget the ears, hairline and sides of the neck.",
            "Wait a few minutes before adding other makeup, and reapply through the day.",
        ]
        case .glowFilter: [
            "Use it on its own for a light glow, or mix a drop into your foundation.",
            "Dot a small amount on the cheekbones, forehead and nose.",
            "Blend with fingertips or a damp sponge until it looks like skin.",
            "Add a little more only where you want extra glow.",
        ]
        case .creamBlush: [
            "Apply after foundation and concealer, before powder.",
            "Start with one or two small dots. Cream and liquid blushes are pigmented.",
            "Smile and place the color on the apples of your cheeks.",
            "Blend up and out toward the temples with fingertips, a sponge or a fluffy brush.",
            "Build one small layer at a time until you like it.",
        ]
        case .powderBlush: [
            "Apply after foundation and powder.",
            "Tap a fluffy brush into the blush and knock off the extra.",
            "Smile and sweep the color across the apples of your cheeks and up toward the temples.",
            "Blend the edges with a clean brush so there are no harsh lines.",
            "Layer more for a bolder color.",
        ]
        case .bronzer: [
            "Apply after foundation, with a fluffy brush or your fingers for cream formulas.",
            "Start where the sun naturally hits: forehead, cheekbones and along the jaw.",
            "Use a light hand and sweep in a loose '3' shape from the temple to the jaw.",
            "Blend the edges until they disappear, then blend into your neck so the color matches.",
            "Build up slowly. It is easier to add than remove.",
        ]
        case .highlighter: [
            "Apply after blush and bronzer.",
            "Place a small amount on the high points: top of the cheekbones, brow bone, bridge of the nose and cupid's bow.",
            "Tap it in with a fingertip or small brush. Do not drag it.",
            "Blend the edges so the glow looks soft, and skip any areas with texture.",
        ]
        case .mascara: [
            "Curl your lashes first if you like.",
            "Wiggle the wand from the roots, then pull it up and out through the tips.",
            "Look slightly down and hold the wand at the base of the upper lashes for a second so it lifts them.",
            "Add a second coat while the first is still tacky, and use the tip of the wand on the corner lashes.",
            "For lower lashes, turn the wand vertically and use light strokes.",
            "Comb through with a clean spoolie if anything clumps.",
        ]
        case .eyeliner: [
            "Rest your elbow on a table to keep your hand steady, and look down into a mirror.",
            "Draw small dashes along the upper lash line instead of one long line.",
            "Connect the dashes, and thicken the line slightly toward the outer corner.",
            "For a wing, point the end toward the tail of your eyebrow and draw a small line, then fill in the triangle.",
            "Fix any mistakes with a cotton swab and let it dry for a few seconds before opening your eyes.",
        ]
        case .brow: [
            "Brush the brows upward with a spoolie.",
            "Fill in any sparse areas with light hair-like strokes, following the direction of your hair growth.",
            "Keep the front of the brow lighter and the tail slightly darker.",
            "Brush through again to soften the lines.",
            "Set with a clear or tinted gel if you want more hold.",
        ]
        case .eyeshadowPalette: [
            "Start with a clean, dry lid. Primer or concealer will help the color last.",
            "Sweep a light matte shade across the whole lid and up to the brow bone as a base.",
            "Use a medium shade in the crease with windshield-wiper motions.",
            "Press a shimmer or darker shade onto the lid with your finger or a flat brush.",
            "Blend the edges well and tap off any fallout before it lands on your face.",
            "Finish with mascara. Do eyeshadow before foundation if you tend to get fallout.",
        ]
        case .lipLiner: [
            "Prep with a little lip balm and let it sink in.",
            "Start at the center of the upper lip and trace each side of the cupid's bow.",
            "Outline the lower lip from the center out to the corners.",
            "Shade in the lips lightly, then blend the line inward with your finger or a lip brush.",
            "Add lipstick or gloss on top for longer wear.",
        ]
        case .liquidLip: [
            "Exfoliate lightly and apply a thin layer of balm, then blot it off.",
            "Outline the lips with the applicator, starting at the center of the cupid's bow.",
            "Fill in the rest of the lips and press them together to spread the color evenly.",
            "Wait about a minute for it to set and avoid touching your lips.",
            "Blot with a tissue and add a second thin layer if you want more color.",
        ]
        case .glossOrOil: [
            "Start with clean, moisturized lips.",
            "Swipe it across the center of the lower lip, then press your lips together.",
            "Add more to the upper lip if you want more shine.",
            "Wear it alone for a sheer look, or over lip liner or lipstick for more color.",
            "Reapply through the day as needed.",
        ]
        case .lipBalm: [
            "Apply to clean lips at any time of the day.",
            "Swipe or dab a thin layer across both lips.",
            "Press your lips together to spread it evenly.",
            "Reapply as often as you like. It also works under lipstick.",
        ]
        case .lipMask: [
            "Apply to clean, dry lips at night.",
            "Use a generous layer, covering the lips completely.",
            "Leave it on overnight. Do not rub it in.",
            "In the morning, wipe off any extra with a tissue.",
            "Use it on a daily basis for softer lips.",
        ]
        }
    }
}
