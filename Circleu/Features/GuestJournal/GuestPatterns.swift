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
    /// Calendar days with at least one entry.
    var daysWritten = 0
    /// 4 weeks only: entries in each 7-day stretch, oldest first, the last ending today.
    var weeks: [(start: Date, count: Int)] = []

    var hasEnough: Bool { taggedCount >= Self.enoughTagged }

    static func == (a: GuestPatterns, b: GuestPatterns) -> Bool {
        a.entryCount == b.entryCount && a.taggedCount == b.taggedCount && a.topPair == b.topPair
            && a.feelings.map(\.tag) == b.feelings.map(\.tag) && a.feelings.map(\.count) == b.feelings.map(\.count)
            && a.contexts.map(\.tag) == b.contexts.map(\.tag) && a.contexts.map(\.count) == b.contexts.map(\.count)
            && a.daysWritten == b.daysWritten && a.weeks.map(\.start) == b.weeks.map(\.start)
            && a.weeks.map(\.count) == b.weeks.map(\.count)
    }

    /// What a tap on a count opens: the entries behind it.
    enum Filter: Hashable, Sendable {
        case feeling(GuestEntryFeeling), context(GuestEntryContext), pair(GuestEntryContext, GuestEntryFeeling)

        var title: String {
            switch self {
            case .feeling(let feeling): feeling.title
            case .context(let context): context.title
            case .pair(let context, let feeling): "\(context.title) and \(feeling.title)"
            }
        }

        func matches(_ entry: GuestJournalEntry) -> Bool {
            switch self {
            case .feeling(let feeling): entry.feeling == feeling
            case .context(let context): entry.context == context
            case .pair(let context, let feeling): entry.context == context && entry.feeling == feeling
            }
        }
    }

    struct Route: Hashable, Sendable {
        let filter: Filter
        let period: Period
    }

    /// Today and the 27 days before it: 28 calendar days.
    static func inPeriod(_ all: [GuestJournalEntry], _ period: Period, now: Date = Date(),
                         calendar: Calendar = .current) -> [GuestJournalEntry] {
        guard period == .fourWeeks else { return all }
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -27, to: today) ?? now
        // Ends at tomorrow's midnight, like the weekly bars, so a future-dated entry is in neither.
        let end = calendar.date(byAdding: .day, value: 1, to: today) ?? now
        return all.filter { $0.createdAt >= start && $0.createdAt < end }
    }

    /// The entries behind one count, newest first, so the list always matches the number tapped.
    static func entries(_ all: [GuestJournalEntry], for route: Route, now: Date = Date(),
                        calendar: Calendar = .current) -> [GuestJournalEntry] {
        inPeriod(all, route.period, now: now, calendar: calendar).filter(route.filter.matches)
            .sorted { $0.createdAt > $1.createdAt }
    }

    static func make(_ all: [GuestJournalEntry], period: Period, now: Date = Date(),
                     calendar: Calendar = .current) -> GuestPatterns {
        let entries = inPeriod(all, period, now: now, calendar: calendar)
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
        let today = calendar.startOfDay(for: now)
        var weeks: [(start: Date, count: Int)] = []
        if period == .fourWeeks {
            for index in (0..<4).reversed() {
                guard let start = calendar.date(byAdding: .day, value: -7 * index - 6, to: today),
                      let end = calendar.date(byAdding: .day, value: -7 * index + 1, to: today) else { continue }
                weeks.append((start, entries.filter { $0.createdAt >= start && $0.createdAt < end }.count))
            }
        }
        return GuestPatterns(entryCount: entries.count,
                             taggedCount: entries.filter { $0.context != nil || $0.feeling != nil }.count,
                             feelings: ranked(\.feeling), contexts: ranked(\.context), topPair: best,
                             daysWritten: Set(entries.map { calendar.startOfDay(for: $0.createdAt) }).count,
                             weeks: weeks)
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
            .navigationDestination(for: GuestPatterns.Route.self) { route in
                GuestPatternEntriesView(route: route, journal: journal, practice: practice)
            }
            .navigationDestination(for: UUID.self) { id in
                GuestEntryDetailView(entryID: id, journal: journal, practice: practice)
            }
        }
        .id(practice.dataGeneration) // Delete all closes anything open in Patterns, as in Journal.
    }

    @ViewBuilder private func content(_ patterns: GuestPatterns) -> some View {
        if patterns.taggedCount == 0 {
            Text("No tags in these 4 weeks.").foregroundStyle(GuestBrand.muted).frame(maxWidth: .infinity)
        } else {
            HStack(spacing: 10) {
                stat(patterns.entryCount, "Entries")
                stat(patterns.daysWritten, "Days written")
                stat(patterns.taggedCount, "Tagged")
            }
            if !patterns.weeks.isEmpty { weekByWeek(patterns.weeks) }
            if let pair = patterns.topPair {
                NavigationLink(value: GuestPatterns.Route(filter: .pair(pair.context, pair.feeling), period: period)) {
                HStack(spacing: 12) {
                    Image(pair.feeling.asset).resizable().scaledToFit().frame(width: 52, height: 52)
                        .accessibilityHidden(true)
                    Text("\(pair.context.title) and \(pair.feeling.title) came up together \(pair.count) times.")
                        .font(GuestBrand.font(.headline, .semibold)).foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8)).accessibilityHidden(true)
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .background(GuestBrand.blue, in: RoundedRectangle(cornerRadius: 20))
                .accessibilityElement(children: .combine)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Shows those entries")
            }
            if !patterns.feelings.isEmpty {
                card("Feelings", rows: patterns.feelings.map { ($0.tag.title, $0.tag.asset, $0.count, .feeling($0.tag)) })
            }
            if !patterns.contexts.isEmpty {
                card("Contexts", rows: patterns.contexts.map { ($0.tag.title, $0.tag.asset, $0.count, .context($0.tag)) })
            }
            Text("Only your own tags. Tap a row to see its entries.")
                .font(GuestBrand.font(.footnote)).foregroundStyle(GuestBrand.muted)
        }
    }

    private func stat(_ value: Int, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)").font(GuestBrand.font(size: 26, relativeTo: .title2, weight: .bold)).foregroundStyle(GuestBrand.ink)
            Text(label).font(GuestBrand.font(.caption)).foregroundStyle(GuestBrand.muted).lineLimit(1).minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14).padding(.vertical, 12).frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    /// One bar per week, one hue: how often I wrote, not how I felt.
    private func weekByWeek(_ weeks: [(start: Date, count: Int)]) -> some View {
        let most = max(weeks.map(\.count).max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Week by week").font(GuestBrand.font(.headline, .semibold)).accessibilityAddTraits(.isHeader)
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                    VStack(spacing: 6) {
                        Text("\(week.count)").font(GuestBrand.font(.caption, .semibold))
                            .foregroundStyle(week.count == 0 ? GuestBrand.muted : GuestBrand.ink)
                        UnevenRoundedRectangle(topLeadingRadius: 6, topTrailingRadius: 6)
                            .fill(week.count == 0 ? GuestBrand.wash : GuestBrand.blue)
                            .frame(height: max(4, 72 * CGFloat(week.count) / CGFloat(most)))
                        Text(index == weeks.count - 1 ? "Last 7 days" : week.start.formatted(.dateTime.day().month(.abbreviated)))
                            .font(GuestBrand.font(.caption2)).foregroundStyle(GuestBrand.muted).lineLimit(1).minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(index == weeks.count - 1 ? "Last 7 days, \(week.count) entries"
                                        : "Week of \(week.start.formatted(.dateTime.day().month(.wide))), \(week.count) entries")
                }
            }
            .frame(height: 118, alignment: .bottom)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
    }

    private func card(_ title: String,
                      rows: [(title: String, asset: String, count: Int, filter: GuestPatterns.Filter)]) -> some View {
        let most = max(rows.map(\.count).max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text(title).font(GuestBrand.font(.headline, .semibold)).accessibilityAddTraits(.isHeader)
            ForEach(rows, id: \.title) { row in
                NavigationLink(value: GuestPatterns.Route(filter: row.filter, period: period)) {
                HStack(spacing: 10) {
                    Image(row.asset).resizable().scaledToFit().frame(width: 30, height: 30).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(row.title).font(GuestBrand.font(.subheadline, .semibold))
                            Spacer(minLength: 8)
                            Text("\(row.count)").font(GuestBrand.font(.subheadline, .semibold)).foregroundStyle(GuestBrand.ink)
                            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GuestBrand.muted).accessibilityHidden(true)
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
                .contentShape(Rectangle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(row.title), \(row.count)")
                }
                .buttonStyle(.plain)
                .accessibilityHint("Shows those entries")
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
    }
}

/// The entries behind one count in Patterns, read and tagged like Journal.
struct GuestPatternEntriesView: View {
    let route: GuestPatterns.Route
    @ObservedObject var journal: GuestJournalViewModel
    @ObservedObject var practice: GuestPracticeViewModel
    @State private var taggingEntry: GuestJournalEntry?

    var body: some View {
        ScrollView {
            switch journal.loadState {
            case .loading:
                ProgressView().frame(maxWidth: .infinity).padding(24)
            case .failed(let message):
                VStack(spacing: 12) {
                    Text(message).multilineTextAlignment(.center)
                    Button("Try again") { Task { await journal.load() } }
                }
                .frame(maxWidth: .infinity).padding(24)
            case .loaded(let all):
                list(GuestPatterns.entries(all, for: route))
            }
        }
        .background(GuestBrand.ice.ignoresSafeArea())
        .navigationTitle(route.filter.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $taggingEntry) { entry in GuestEntryTagPicker(entry: entry, journal: journal) }
    }

    private func list(_ entries: [GuestJournalEntry]) -> some View {
            LazyVStack(alignment: .leading, spacing: 8) {
                if !entries.isEmpty {
                    Text("\(entries.count) \(entries.count == 1 ? "entry" : "entries") · \(route.period == .fourWeeks ? "last 4 weeks" : "all time")")
                        .font(GuestBrand.font(.subheadline, .semibold)).foregroundStyle(GuestBrand.muted)
                }
                if entries.isEmpty {
                    // Retagging an entry here can leave nothing behind this count.
                    Text("No entries left here.").foregroundStyle(GuestBrand.muted).frame(maxWidth: .infinity)
                }
                // Dated like Journal, since a row shows only the time.
                ForEach(GuestJournalDayGroup.make(entries)) { group in
                    Text(group.id, format: .dateTime.day().month(.abbreviated).year())
                        .font(GuestBrand.font(.footnote, .semibold)).foregroundStyle(GuestBrand.muted)
                        .accessibilityAddTraits(.isHeader).padding(.top, 8)
                    ForEach(group.entries) { entry in
                        GuestJournalRow(entry: entry, hasPractice: !practice.linkedMessages(to: entry.id).isEmpty,
                                        onTags: { taggingEntry = entry })
                    }
                }
            }
            .padding(24)
    }
}
