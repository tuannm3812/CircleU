import CoreText
import SwiftUI
import WidgetKit

struct PocketCardEntry: TimelineEntry {
    let date: Date
    let card: GuestPocketCardSnapshot?
}

/// One entry and no refresh schedule: the app reloads the widget when the card changes.
struct PocketCardProvider: TimelineProvider {
    private static let sample = GuestPocketCardSnapshot(
        wording: "Could we agree on the slides before Friday?", want: nil,
        steadyingLine: "One breath, then the first sentence.", tone: "Balanced", made: .now, messageID: nil)

    func placeholder(in context: Context) -> PocketCardEntry { PocketCardEntry(date: .now, card: Self.sample) }

    func getSnapshot(in context: Context, completion: @escaping (PocketCardEntry) -> Void) {
        let saved = GuestPocketCardShelf.standard.load()
        completion(PocketCardEntry(date: .now, card: saved ?? (context.isPreview ? Self.sample : nil)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PocketCardEntry>) -> Void) {
        let entry = PocketCardEntry(date: .now, card: GuestPocketCardShelf.standard.load())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

private enum PocketType {
    /// Plus Jakarta Sans, bundled with this extension. Falls back to the system font.
    static let family: String? = {
        guard let url = Bundle.main.url(forResource: "PlusJakartaSans", withExtension: "ttf") else { return nil }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        return "Plus Jakarta Sans"
    }()

    static func font(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        family.map { Font.custom($0, fixedSize: size).weight(weight) } ?? .system(size: size, weight: weight)
    }
}

struct PocketCardWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PocketCardEntry

    private var firm: Bool { entry.card?.tone == "Firm" }
    private var ink: Color { firm ? .white : Color(red: 13 / 255, green: 20 / 255, blue: 33 / 255) }

    private var art: String {
        switch entry.card?.tone {
        case "Soft": "GuestFeelingCalm"
        case "Firm": "GuestPinguPractising"
        default: "GuestPinguThumbsUp"
        }
    }

    var body: some View {
        content
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(for: .widget) { background }
            .widgetURL(GuestPocketCardShelf.openURL)
    }

    @ViewBuilder private var content: some View {
        if let card = entry.card {
            if family == .systemSmall { small(card) } else { medium(card) }
        } else {
            empty
        }
    }

    /// Small has room for the steadying line only; a tap opens the whole card.
    private func small(_ card: GuestPocketCardSnapshot) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Image(art).resizable().scaledToFit().frame(width: 62, height: 62).offset(x: 6, y: 6)
            VStack(alignment: .leading, spacing: 4) {
                Text("Before I talk").font(PocketType.font(10, .bold)).textCase(.uppercase).opacity(0.85)
                Text(card.steadyingLine).font(PocketType.font(15, .bold)).lineLimit(4).minimumScaleFactor(0.75)
                    .privacySensitive()
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    /// Medium shows the wording, ending in an ellipsis if it is long; a tap opens the whole card.
    private func medium(_ card: GuestPocketCardSnapshot) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Before I talk").font(PocketType.font(10, .bold)).textCase(.uppercase).opacity(0.85)
                Text(card.wording).font(PocketType.font(15, .bold)).lineLimit(4).minimumScaleFactor(0.8)
                    .privacySensitive()
                Spacer(minLength: 0)
                Text(card.steadyingLine).font(PocketType.font(12, .semibold)).lineLimit(2).minimumScaleFactor(0.8)
                    .privacySensitive()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            Image(art).resizable().scaledToFit().frame(width: 76, height: 76).offset(x: 6, y: 6)
        }
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("No card yet").font(PocketType.font(15, .bold))
            Text("Make a pocket card in Practice.").font(PocketType.font(12, .regular)).opacity(0.85)
            Spacer(minLength: 0)
            Image("GuestIconLogo").resizable().scaledToFit().frame(width: 20, height: 20)
        }
    }

    @ViewBuilder private var background: some View {
        switch entry.card?.tone {
        case "Soft":
            LinearGradient(colors: [Color(red: 0.91, green: 0.95, blue: 1), Color(red: 0.81, green: 0.89, blue: 1)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        case "Firm":
            LinearGradient(colors: [Color(red: 0.05, green: 0.19, blue: 0.45), Color(red: 0.02, green: 0.31, blue: 0.79)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            LinearGradient(colors: [.white, Color(red: 0.89, green: 0.93, blue: 1)], startPoint: .top, endPoint: .bottom)
        }
    }
}

struct CircleUPocketCardWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: GuestPocketCardShelf.widgetKind, provider: PocketCardProvider()) { entry in
            PocketCardWidgetView(entry: entry)
        }
        .configurationDisplayName("Pocket card")
        .description("Your words, ready before you talk.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct CircleUWidgets: WidgetBundle {
    var body: some Widget { CircleUPocketCardWidget() }
}
