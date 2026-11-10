import SwiftUI

/// Settings > How Recommendations Work: the research behind personalization, with citations.
struct ResearchView: View {
    @Environment(AppStore.self) private var store
    private let research = Research.shared

    private var activeRules: [Research.Rule] {
        research.rules.filter { $0.applies(to: store.profile) }
    }

    var body: some View {
        List {
            Section {
                Text("Made You Look ranks products by matching your quiz answers to formula traits that dermatologists and makeup artists recommend. Each card shows the main reason it was picked.")
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.ink)
                    .listRowBackground(Theme.surface)
            }

            Section("Applied to your profile") {
                if activeRules.isEmpty && store.profile.budget == nil && store.profile.skinTone == nil {
                    Text("Add a skin type, concerns, skin tone or budget in your Beauty Profile to personalize recommendations.")
                        .font(Theme.body(13))
                        .foregroundStyle(Theme.inkSecondary)
                }
                ForEach(activeRules) { rule in
                    ruleRow(rule)
                }
                if let tone = store.profile.skinTone {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Shades for \(tone.title.lowercased()) skin").font(Theme.body(15, .semibold))
                        Text("Blush: \(research.shadeGuides["blush"]?.tones?[tone.rawValue]?.advice ?? "")")
                        Text("Lips: \(research.shadeGuides["lips"]?.tones?[tone.rawValue]?.advice ?? "")")
                        Text("Bronzer: \(research.shadeGuides["bronzer"]?.advice ?? "")")
                    }
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.ink)
                }
                if let budget = store.profile.budget {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Budget: \(budget.title)").font(Theme.body(15, .semibold))
                        Text(budget == .any ? "All price points are shown." : "Products \(budget.hint.lowercased()) rank higher; others rank lower but stay visible.")
                            .font(Theme.body(13))
                    }
                    .foregroundStyle(Theme.ink)
                }
            }
            .listRowBackground(Theme.surface)

            Section("All rules") {
                ForEach(research.rules) { rule in
                    ruleRow(rule)
                }
            }
            .listRowBackground(Theme.surface)

            Section("Shade guidance") {
                shadeGuideRow(title: "Blush", key: "blush")
                shadeGuideRow(title: "Lips", key: "lips")
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bronzer").font(Theme.body(15, .semibold))
                    Text(research.shadeGuides["bronzer"]?.advice ?? "").font(Theme.body(13))
                    sourceLinks(research.shadeGuides["bronzer"]?.sources ?? [])
                }
                Text("Shades are matched by comparing each shade's lightness (sampled from retailer swatches) with the depth range these guides recommend for your skin tone. Foundation and concealer shades are matched to your tone directly.")
                    .font(Theme.body(12))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .listRowBackground(Theme.surface)

            Section("How the score works") {
                Text("""
                • +\(Personalizer.ruleMatchWeight) for each rule a product satisfies; −\(Personalizer.ruleConflictPenalty) if it has a trait a rule says to avoid
                • +\(Personalizer.shadeWeight) if it has a shade suited to your skin tone
                • ±\(Personalizer.budgetWeight) for being inside or outside your budget
                • +\(Personalizer.styleWeight) per makeup style you picked
                • Products you already own are listed last
                """)
                .font(Theme.body(13))
                .foregroundStyle(Theme.ink)
                Text("Product traits (matte, hydrating, fragrance-free…) come from Sephora and Ulta product descriptions. Recommendations are general guidance, not medical advice. See a dermatologist for skin conditions.")
                    .font(Theme.body(12))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .listRowBackground(Theme.surface)

            Section("Sources (\(research.sources.count))") {
                ForEach(research.sources) { source in
                    VStack(alignment: .leading, spacing: 4) {
                        Link(destination: source.url) {
                            Text(source.title)
                                .font(Theme.body(14, .semibold))
                                .foregroundStyle(Theme.primaryDark)
                                .multilineTextAlignment(.leading)
                        }
                        Text("\(source.publisher) · \(source.kind)")
                            .font(Theme.body(12))
                            .foregroundStyle(Theme.inkSecondary)
                        Text(source.finding)
                            .font(Theme.body(12))
                            .foregroundStyle(Theme.ink)
                    }
                    .padding(.vertical, 2)
                }
                Text("Research compiled \(research.updated).")
                    .font(Theme.body(11))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .listRowBackground(Theme.surface)
        }
        .scrollContentBackground(.hidden)
        .appBackground()
        .navigationTitle("How Recommendations Work")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    private func ruleRow(_ rule: Research.Rule) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(rule.title).font(Theme.body(15, .semibold))
            Text(rule.explanation).font(Theme.body(13))
            Text("Favors: " + rule.prefer.map(\.title).joined(separator: ", ")
                 + (rule.avoid.isEmpty ? "" : " · Avoids: " + rule.avoid.map(\.title).joined(separator: ", ")))
                .font(Theme.body(12))
                .foregroundStyle(Theme.inkSecondary)
            sourceLinks(rule.sources)
        }
        .foregroundStyle(Theme.ink)
        .padding(.vertical, 2)
    }

    private func shadeGuideRow(title: String, key: String) -> some View {
        let guide = research.shadeGuides[key]
        return VStack(alignment: .leading, spacing: 4) {
            Text(title).font(Theme.body(15, .semibold))
            ForEach(SkinTone.allCases) { tone in
                if let advice = guide?.tones?[tone.rawValue]?.advice {
                    Text("\(tone.title): \(advice)").font(Theme.body(12))
                }
            }
            sourceLinks(guide?.sources ?? [])
        }
        .foregroundStyle(Theme.ink)
    }

    private func sourceLinks(_ ids: [String]) -> some View {
        let sources = ids.compactMap(research.source)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) { links(sources) }
            VStack(alignment: .leading, spacing: 2) { links(sources) }
        }
        .font(Theme.body(11, .medium))
    }

    @ViewBuilder
    private func links(_ sources: [Research.Source]) -> some View {
        ForEach(sources) { source in
            Link(destination: source.url) {
                Label(source.publisher, systemImage: "link")
                    .foregroundStyle(Theme.primary)
                    .lineLimit(1)
            }
        }
    }
}
