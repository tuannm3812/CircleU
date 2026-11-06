import Combine
import CoreTransferable
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// A card to glance at before the real conversation. Everything on it is something the person
/// wrote or chose: their wording, what they want to happen (when they said), and one steadying
/// line. Nothing is generated about them, and nothing leaves the phone unless they share it.
struct GuestPocketCard: Equatable, Sendable {
    /// The same three tones as Practice, so the card follows the tone already chosen there.
    enum Tone: String, CaseIterable, Identifiable, Sendable {
        case soft = "Soft", balanced = "Balanced", firm = "Firm"
        var id: String { rawValue }

        /// Existing Pingu art for now; dedicated card illustrations are a later asset batch.
        var asset: String {
            switch self {
            case .soft: "GuestFeelingCalm"
            case .balanced: "GuestPinguThumbsUp"
            case .firm: "GuestPinguPractising"
            }
        }
    }

    var wording: String
    /// What the person wants to happen; left off when they gave no goal.
    var want: String?
    var steadyingLine: String
    var tone: Tone

    static let steadyingLineLimit = 60
    static let steadyingLines = [
        "One breath, then the first sentence.",
        "I can say it kindly and still say it.",
        "It’s okay to pause.",
        "I only need to say my part.",
        "Slow is fine.",
        "I prepared for this.",
    ]
    /// A 4:5 image, the shape Photos and messages show without cropping.
    static let exportSize = CGSize(width: 1080, height: 1350)

    /// Long wording gets smaller type, so a full practised message still fits the card. Past the
    /// last tier the text shrinks further and, as a last resort, ends in an ellipsis: never cut
    /// off without a sign.
    static func wordingPointSize(for wording: String) -> CGFloat {
        switch wording.count {
        case ...80: 24
        case ...160: 20
        case ...260: 17
        default: 14
        }
    }
}

/// The image handed to the share sheet, drawn only when the person actually shares or saves.
struct GuestPocketCardExport: Transferable {
    let card: GuestPocketCard

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { export in
            guard let data = await MainActor.run(body: { GuestPocketCardModel.renderImage(of: export.card)?.pngData() }) else {
                throw CocoaError(.fileWriteUnknown)
            }
            return data
        }
        .suggestedFileName("CircleU pocket card")
    }
}

@MainActor
final class GuestPocketCardModel: ObservableObject {
    private let wording: String
    private let goal: String
    @Published var tone: GuestPocketCard.Tone
    @Published private(set) var chosenLine = GuestPocketCard.steadyingLines[0]
    /// "Write my own": used in place of the chosen line while it has words. Capped as it is
    /// typed, so what the field shows is exactly what the card says.
    @Published var ownLine = "" {
        didSet {
            if ownLine.count > GuestPocketCard.steadyingLineLimit {
                ownLine = String(ownLine.prefix(GuestPocketCard.steadyingLineLimit))
            }
        }
    }

    init(wording: String, goal: String, tone: String) {
        self.wording = wording.trimmingCharacters(in: .whitespacesAndNewlines)
        self.goal = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        self.tone = GuestPocketCard.Tone(rawValue: tone) ?? .balanced
    }

    func choose(_ line: String) {
        guard GuestPocketCard.steadyingLines.contains(line) else { return }
        chosenLine = line
    }

    var card: GuestPocketCard {
        let own = ownLine.trimmingCharacters(in: .whitespacesAndNewlines)
        return GuestPocketCard(wording: wording, want: goal.isEmpty ? nil : goal,
                               steadyingLine: own.isEmpty ? chosenLine : own, tone: tone)
    }

    func renderImage() -> UIImage? { Self.renderImage(of: card) }

    /// The card as an image for the share sheet (Save Image, Messages, AirDrop).
    static func renderImage(of card: GuestPocketCard) -> UIImage? {
        let size = GuestPocketCard.exportSize
        let renderer = ImageRenderer(content: GuestPocketCardView(card: card, scale: size.width / 360)
            .frame(width: size.width, height: size.height))
        renderer.scale = 1
        renderer.isOpaque = true
        return renderer.uiImage
    }
}

/// The card itself, drawn at a 360-point design width and scaled for export.
struct GuestPocketCardView: View {
    let card: GuestPocketCard
    var scale: CGFloat = 1

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            background
            Image(card.tone.asset).resizable().scaledToFit()
                .frame(width: 150 * scale, height: 150 * scale)
                .padding(.trailing, 4 * scale).padding(.bottom, 4 * scale)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 12 * scale) {
                Text("Before I talk").font(font(12, .bold)).tracking(1 * scale).textCase(.uppercase).opacity(0.85)
                // Sized by length, then allowed to shrink; it takes the room before anything else does.
                Text(card.wording).font(font(GuestPocketCard.wordingPointSize(for: card.wording), .bold))
                    .minimumScaleFactor(0.5).layoutPriority(2)
                if let want = card.want {
                    VStack(alignment: .leading, spacing: 3 * scale) {
                        Text("What I want").font(font(11, .bold)).tracking(0.8 * scale).textCase(.uppercase).opacity(0.8)
                        Text(want).font(font(15, .regular)).lineLimit(2).minimumScaleFactor(0.8)
                    }
                    .padding(.trailing, 110 * scale)
                }
                Spacer(minLength: 8 * scale)
                Text(card.steadyingLine).font(font(16, .semibold)).lineLimit(3).minimumScaleFactor(0.7)
                    .layoutPriority(1).padding(.trailing, 150 * scale)
                HStack(spacing: 6 * scale) {
                    Image("GuestIconLogo").resizable().scaledToFit().frame(width: 18 * scale, height: 18 * scale)
                    Text("CircleU").font(font(12, .semibold)).opacity(0.85)
                }
                .accessibilityHidden(true)
            }
            .foregroundStyle(ink)
            .padding(24 * scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenSummary)
    }

    private var spokenSummary: String {
        ["Pocket card.", card.wording, card.want.map { "What I want: \($0)" }, card.steadyingLine]
            .compactMap { $0 }.joined(separator: " ")
    }

    private func font(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        GuestBrand.font(size: size * scale, relativeTo: .body, weight: weight)
    }

    private var ink: Color { card.tone == .firm ? .white : GuestBrand.ink }

    @ViewBuilder private var background: some View {
        switch card.tone {
        case .soft:
            LinearGradient(colors: [Color(red: 0.91, green: 0.95, blue: 1), Color(red: 0.81, green: 0.89, blue: 1)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        case .balanced:
            LinearGradient(colors: [.white, GuestBrand.wash], startPoint: .top, endPoint: .bottom)
        case .firm:
            GuestBrand.blue
        }
    }
}

/// Make the card: tone, a steadying line (or my own), then share or save the image.
struct GuestPocketCardSheet: View {
    @StateObject private var model: GuestPocketCardModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @FocusState private var writingOwn: Bool

    init(wording: String, goal: String, tone: String) {
        _model = StateObject(wrappedValue: GuestPocketCardModel(wording: wording, goal: goal, tone: tone))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GuestPocketCardView(card: model.card)
                        .aspectRatio(GuestPocketCard.exportSize.width / GuestPocketCard.exportSize.height, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: GuestBrand.ink.opacity(0.12), radius: 12, y: 4)
                    Text("Tone").font(GuestBrand.font(.headline, .semibold))
                    ViewThatFits(in: .horizontal) {
                        HStack { toneButtons }
                        VStack(alignment: .leading) { toneButtons }
                    }
                    Text("A steadying line").font(GuestBrand.font(.headline, .semibold))
                    ForEach(GuestPocketCard.steadyingLines, id: \.self) { line in
                        let selected = model.card.steadyingLine == line
                        Button { writingOwn = false; model.ownLine = ""; model.choose(line) } label: {
                            HStack {
                                Text(line).fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 8)
                                if selected { Image(systemName: "checkmark").accessibilityHidden(true) }
                            }
                            .font(GuestBrand.font(.subheadline, .semibold)).foregroundStyle(GuestBrand.ink)
                            .padding(.horizontal, 14).frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                            .background(.white, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(selected ? GuestBrand.blue : .clear, lineWidth: 2))
                        }
                        .buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
                    }
                    TextField("Write my own", text: $model.ownLine, prompt: Text("Or write your own"), axis: .vertical)
                        .lineLimit(1...2).focused($writingOwn)
                        .padding(14).background(.white, in: RoundedRectangle(cornerRadius: 14))
                        .accessibilityLabel("Write my own")
                    Text("\(model.ownLine.count) of \(GuestPocketCard.steadyingLineLimit)")
                        .font(GuestBrand.font(.caption)).foregroundStyle(GuestBrand.muted)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .accessibilityLabel("\(model.ownLine.count) of \(GuestPocketCard.steadyingLineLimit) characters")
                    Text("Made on this iPhone from your own words. Sharing sends it where you choose.")
                        .font(GuestBrand.font(.footnote)).foregroundStyle(GuestBrand.muted)
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                share.padding(.horizontal, 24).padding(.vertical, 12).background(GuestBrand.ice)
            }
            .background(GuestBrand.ice.ignoresSafeArea())
            .navigationTitle("Pocket card").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var toneButtons: some View {
        ForEach(GuestPocketCard.Tone.allCases) { tone in
            Button { model.tone = tone } label: {
                Text(tone.rawValue).font(GuestBrand.font(.subheadline, .semibold)).fixedSize()
                    .padding(.horizontal, 16).frame(minHeight: 44)
                    .background(model.tone == tone ? GuestBrand.blue.opacity(0.15) : .white, in: Capsule())
            }
            .buttonStyle(.plain).accessibilityAddTraits(model.tone == tone ? .isSelected : [])
            .accessibilityLabel("\(tone.rawValue) card")
        }
    }

    /// The system share sheet: Save Image, Messages, AirDrop. The image is drawn only when asked for.
    private var share: some View {
        ShareLink(item: GuestPocketCardExport(card: model.card),
                  preview: SharePreview("Pocket card", image: Image("GuestIconLogo"))) {
            Text("Share or save")
        }
        .buttonStyle(GuestBrandButtonStyle())
    }
}
