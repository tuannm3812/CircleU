import SwiftUI

/// What the person's own tags add up to. Counts only: nothing here is guessed from their words,
/// and an untagged entry stays untagged.
nonisolated struct GuestPatterns: Equatable, Sendable {
    enum Period: String, CaseIterable, Identifiable, Sendable {
        case fourWeeks = "4 weeks", allTime = "All time"
        var id: String { rawValue }
    }

    struct Pair: Equatable, Sendable {
        let context: GuestEntryContext
        let feeling: GuestEntryFeeling
        let count: Int
    }

    /// Tagged entries needed before counts mean anything.
    static let enoughTagged = 3

    var entryCount = 0
    var taggedCount = 0
    /// Most often first; ties keep the order the tags are offered in.
    var feelings: [(tag: GuestEntryFeeling, count: Int)] = []
    var contexts: [(tag: GuestEntryContext, count: Int)] = []
    /// The context and feeling chosen together most often, when that happened more than once.
    var topPair: Pair?

    var hasEnough: Bool { taggedCount >= Self.enoughTagged }

    static func == (a: GuestPatterns, b: GuestPatterns) -> Bool {
        a.entryCount == b.entryCount && a.taggedCount == b.taggedCount && a.topPair == b.topPair
            && a.feelings.map(\.tag) == b.feelings.map(\.tag) && a.feelings.map(\.count) == b.feelings.map(\.count)
            && a.contexts.map(\.tag) == b.contexts.map(\.tag) && a.contexts.map(\.count) == b.contexts.map(\.count)
    }

    static func make(_ all: [GuestJournalEntry], period: Period, now: Date = Date(),
                     calendar: Calendar = .current) -> GuestPatterns {
        // Today and the 27 days before it: 28 calendar days.
        let start = calendar.date(byAdding: .day, value: -27, to: calendar.startOfDay(for: now)) ?? now
        let entries = period == .allTime ? all : all.filter { $0.createdAt >= start }
        func ranked<Tag: CaseIterable & Hashable>(_ tag: (GuestJournalEntry) -> Tag?) -> [(tag: Tag, count: Int)] {
            let counts = Dictionary(grouping: entries.compactMap(tag), by: { $0 }).mapValues(\.count)
            let order = Array(Tag.allCases)
            return order.compactMap { item in counts[item].map { (tag: item, count: $0) } }
                .enumerated().sorted { ($1.element.count, $0.offset) < ($0.element.count, $1.offset) }.map(\.element)
        }
        var pairs: [Pair] = []
        for context in GuestEntryContext.allCases {
            for feeling in GuestEntryFeeling.allCases {
                let count = entries.filter { $0.context == context && $0.feeling == feeling }.count
                if count > 1 { pairs.append(Pair(context: context, feeling: feeling, count: count)) }
            }
        }
        var best: Pair?
        for pair in pairs where pair.count > (best?.count ?? 0) { best = pair }
        return GuestPatterns(entryCount: entries.count,
                             taggedCount: entries.filter { $0.context != nil || $0.feeling != nil }.count,
                             feelings: ranked(\.feeling), contexts: ranked(\.context), topPair: best)
    }
}

struct GuestPatternsView: View {
    @ObservedObject var journal: GuestJournalViewModel
    @ObservedObject var practice: GuestPracticeViewModel
    @State private var period = GuestPatterns.Period.fourWeeks

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GuestPageTop(heading: "What keeps coming up", scene: .keepsakeShelf)
                    switch journal.loadState {
                    case .loading:
                        ProgressView().frame(maxWidth: .infinity)
                    case .failed(let message):
                        VStack(spacing: 12) {
                            Text(message).multilineTextAlignment(.center)
                            Button("Try again") { Task { await journal.load() } }
                        }
                        .frame(maxWidth: .infinity)
                    case .loaded(let entries):
                        if GuestPatterns.make(entries, period: .allTime).hasEnough {
                            Picker("Period", selection: $period) {
                                ForEach(GuestPatterns.Period.allCases) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            content(.make(entries, period: period))
                        } else {
                            Text("Tag a few entries and your patterns show here.")
                                .foregroundStyle(GuestBrand.muted).multilineTextAlignment(.center).frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(24)
            }
            .background(GuestBrand.ice.ignoresSafeArea())
            .navigationTitle("Patterns")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { GuestBrandToolbar(journal: journal, practice: practice) }
        }
    }

    @ViewBuilder private func content(_ patterns: GuestPatterns) -> some View {
        if patterns.taggedCount == 0 {
            Text("No tags in these 4 weeks.").foregroundStyle(GuestBrand.muted).frame(maxWidth: .infinity)
        } else {
            if let pair = patterns.topPair {
                HStack(spacing: 12) {
                    Image(pair.feeling.asset).resizable().scaledToFit().frame(width: 52, height: 52)
                        .accessibilityHidden(true)
                    Text("\(pair.context.title) and \(pair.feeling.title) came up together \(pair.count) times.")
                        .font(GuestBrand.font(.headline, .semibold)).foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .background(GuestBrand.blue, in: RoundedRectangle(cornerRadius: 20))
                .accessibilityElement(children: .combine)
            }
            if !patterns.feelings.isEmpty {
                card("Feelings", rows: patterns.feelings.map { ($0.tag.title, $0.tag.asset, $0.count) })
            }
            if !patterns.contexts.isEmpty {
                card("Contexts", rows: patterns.contexts.map { ($0.tag.title, $0.tag.asset, $0.count) })
            }
            Text("From \(patterns.taggedCount) tagged of \(patterns.entryCount) entries. Only your own tags.")
                .font(GuestBrand.font(.footnote)).foregroundStyle(GuestBrand.muted)
        }
    }

    private func card(_ title: String, rows: [(title: String, asset: String, count: Int)]) -> some View {
        let most = max(rows.map(\.count).max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text(title).font(GuestBrand.font(.headline, .semibold)).accessibilityAddTraits(.isHeader)
            ForEach(rows, id: \.title) { row in
                HStack(spacing: 10) {
                    Image(row.asset).resizable().scaledToFit().frame(width: 30, height: 30).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(row.title).font(GuestBrand.font(.subheadline, .semibold))
                            Spacer(minLength: 8)
                            Text("\(row.count)").font(GuestBrand.font(.subheadline, .semibold)).foregroundStyle(GuestBrand.blue)
                        }
                        Capsule().fill(GuestBrand.wash).frame(height: 8)
                            .overlay(alignment: .leading) {
                                GeometryReader { geometry in
                                    Capsule().fill(GuestBrand.blue)
                                        .frame(width: geometry.size.width * CGFloat(row.count) / CGFloat(most))
                                }
                            }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(row.title), \(row.count)")
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
    }
}
