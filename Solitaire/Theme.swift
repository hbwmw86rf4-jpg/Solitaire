import SwiftUI

enum TableTheme: String, CaseIterable, Identifiable {
    case green, blue, crimson, purple, charcoal, tan
    case midnight, lagoon, sunset, aurora, rosewood, slate

    var id: String { rawValue }

    var name: String {
        switch self {
        case .green: "Classic Green"
        case .blue: "Ocean"
        case .crimson: "Casino Red"
        case .purple: "Velvet"
        case .charcoal: "Charcoal"
        case .tan: "Walnut"
        case .midnight: "Midnight"
        case .lagoon: "Lagoon"
        case .sunset: "Sunset"
        case .aurora: "Aurora"
        case .rosewood: "Rosewood"
        case .slate: "Slate"
        }
    }

    /// Light, mid and deep tones of the cloth, top to bottom.
    var colors: [Color] {
        switch self {
        case .green:
            [Color(red: 0.09, green: 0.42, blue: 0.27), Color(red: 0.07, green: 0.36, blue: 0.22), Color(red: 0.03, green: 0.17, blue: 0.10)]
        case .blue:
            [Color(red: 0.10, green: 0.33, blue: 0.52), Color(red: 0.06, green: 0.25, blue: 0.43), Color(red: 0.02, green: 0.11, blue: 0.22)]
        case .crimson:
            [Color(red: 0.55, green: 0.10, blue: 0.14), Color(red: 0.45, green: 0.07, blue: 0.11), Color(red: 0.20, green: 0.02, blue: 0.05)]
        case .purple:
            [Color(red: 0.36, green: 0.18, blue: 0.50), Color(red: 0.28, green: 0.13, blue: 0.41), Color(red: 0.12, green: 0.05, blue: 0.19)]
        case .charcoal:
            [Color(white: 0.30), Color(white: 0.22), Color(white: 0.08)]
        case .tan:
            [Color(red: 0.55, green: 0.38, blue: 0.22), Color(red: 0.45, green: 0.30, blue: 0.17), Color(red: 0.22, green: 0.13, blue: 0.06)]
        case .midnight:
            [Color(red: 0.11, green: 0.15, blue: 0.33), Color(red: 0.06, green: 0.09, blue: 0.23), Color(red: 0.02, green: 0.03, blue: 0.09)]
        case .lagoon:
            [Color(red: 0.05, green: 0.46, blue: 0.48), Color(red: 0.03, green: 0.36, blue: 0.40), Color(red: 0.01, green: 0.16, blue: 0.20)]
        case .sunset:
            [Color(red: 0.72, green: 0.34, blue: 0.20), Color(red: 0.54, green: 0.17, blue: 0.30), Color(red: 0.19, green: 0.06, blue: 0.22)]
        case .aurora:
            [Color(red: 0.07, green: 0.46, blue: 0.40), Color(red: 0.10, green: 0.27, blue: 0.48), Color(red: 0.10, green: 0.06, blue: 0.26)]
        case .rosewood:
            [Color(red: 0.53, green: 0.25, blue: 0.33), Color(red: 0.40, green: 0.16, blue: 0.24), Color(red: 0.17, green: 0.05, blue: 0.10)]
        case .slate:
            [Color(red: 0.28, green: 0.35, blue: 0.43), Color(red: 0.20, green: 0.26, blue: 0.33), Color(red: 0.07, green: 0.10, blue: 0.14)]
        }
    }

    var deep: Color { colors[2] }
}

enum CardBackPattern {
    case lattice, stripes, dots, plain, argyle, sunburst, chevrons, rings
}

enum CardBackTheme: String, CaseIterable, Identifiable {
    case crimson, navy, emerald, midnight, rose, ocean
    case amethyst, sunburst, slate, copper, carbon, sky

    var id: String { rawValue }

    var name: String {
        switch self {
        case .crimson: "Crimson"
        case .navy: "Navy"
        case .emerald: "Emerald"
        case .midnight: "Midnight Gold"
        case .rose: "Rose"
        case .ocean: "Teal Stripe"
        case .amethyst: "Amethyst"
        case .sunburst: "Sunburst"
        case .slate: "Slate"
        case .copper: "Copper"
        case .carbon: "Carbon"
        case .sky: "Sky"
        }
    }

    var top: Color {
        switch self {
        case .crimson: Color(red: 0.60, green: 0.09, blue: 0.16)
        case .navy: Color(red: 0.16, green: 0.24, blue: 0.56)
        case .emerald: Color(red: 0.06, green: 0.46, blue: 0.32)
        case .midnight: Color(white: 0.16)
        case .rose: Color(red: 0.86, green: 0.45, blue: 0.55)
        case .ocean: Color(red: 0.05, green: 0.50, blue: 0.55)
        case .amethyst: Color(red: 0.46, green: 0.25, blue: 0.68)
        case .sunburst: Color(red: 0.93, green: 0.54, blue: 0.20)
        case .slate: Color(red: 0.37, green: 0.44, blue: 0.53)
        case .copper: Color(red: 0.72, green: 0.42, blue: 0.24)
        case .carbon: Color(white: 0.21)
        case .sky: Color(red: 0.36, green: 0.62, blue: 0.92)
        }
    }

    var bottom: Color {
        switch self {
        case .crimson: Color(red: 0.32, green: 0.03, blue: 0.08)
        case .navy: Color(red: 0.07, green: 0.10, blue: 0.30)
        case .emerald: Color(red: 0.02, green: 0.22, blue: 0.15)
        case .midnight: Color(white: 0.03)
        case .rose: Color(red: 0.55, green: 0.18, blue: 0.30)
        case .ocean: Color(red: 0.02, green: 0.25, blue: 0.32)
        case .amethyst: Color(red: 0.20, green: 0.08, blue: 0.36)
        case .sunburst: Color(red: 0.64, green: 0.17, blue: 0.20)
        case .slate: Color(red: 0.15, green: 0.19, blue: 0.26)
        case .copper: Color(red: 0.36, green: 0.16, blue: 0.08)
        case .carbon: Color(white: 0.05)
        case .sky: Color(red: 0.13, green: 0.31, blue: 0.66)
        }
    }

    var accent: Color {
        switch self {
        case .rose: Color(red: 1.0, green: 0.92, blue: 0.88)
        case .ocean: Color(red: 0.85, green: 0.97, blue: 0.95)
        case .sunburst, .copper: Color(red: 1.0, green: 0.94, blue: 0.80)
        case .slate: Color(red: 0.88, green: 0.91, blue: 0.95)
        case .carbon: Color(red: 0.96, green: 0.27, blue: 0.30)
        case .sky: .white
        default: Felt.gold
        }
    }

    var pattern: CardBackPattern {
        switch self {
        case .crimson, .navy, .sky: .lattice
        case .emerald, .rose: .dots
        case .ocean, .carbon: .stripes
        case .midnight: .plain
        case .amethyst: .argyle
        case .sunburst: .sunburst
        case .slate: .chevrons
        case .copper: .rings
        }
    }
}

enum FaceTheme: String, CaseIterable, Identifiable {
    case classic, fourColor, largePrint, night, vintage, neon

    var id: String { rawValue }

    var name: String {
        switch self {
        case .classic: "Classic"
        case .fourColor: "Four-Color"
        case .largePrint: "Large Print"
        case .night: "Night"
        case .vintage: "Vintage"
        case .neon: "Neon"
        }
    }

    var detail: String {
        switch self {
        case .classic: "Red and black suits."
        case .fourColor: "Each suit has its own color."
        case .largePrint: "Bigger corner labels."
        case .night: "Dark cards that are easy on the eyes."
        case .vintage: "Aged paper with oxblood and sepia ink."
        case .neon: "Black cards, a glowing color per suit."
        }
    }

    func ink(for suit: Suit) -> Color {
        switch self {
        case .fourColor:
            switch suit {
            case .spades: Felt.ink
            case .hearts: Felt.red
            case .diamonds: Color(red: 0.10, green: 0.36, blue: 0.78)
            case .clubs: Color(red: 0.06, green: 0.50, blue: 0.24)
            }
        case .night:
            suit.isRed ? Color(red: 1.0, green: 0.42, blue: 0.43) : Color(red: 0.90, green: 0.91, blue: 0.95)
        case .vintage:
            suit.isRed ? Color(red: 0.60, green: 0.13, blue: 0.10) : Color(red: 0.24, green: 0.17, blue: 0.12)
        case .neon:
            switch suit {
            case .spades: Color(red: 0.36, green: 0.90, blue: 1.0)
            case .hearts: Color(red: 1.0, green: 0.31, blue: 0.62)
            case .diamonds: Color(red: 1.0, green: 0.78, blue: 0.26)
            case .clubs: Color(red: 0.46, green: 1.0, blue: 0.52)
            }
        case .classic, .largePrint:
            suit.isRed ? Felt.red : Felt.ink
        }
    }

    /// The card stock, top to bottom.
    var paper: [Color] {
        switch self {
        case .night: [Color(red: 0.19, green: 0.20, blue: 0.25), Color(red: 0.11, green: 0.12, blue: 0.16)]
        case .vintage: [Color(red: 0.97, green: 0.92, blue: 0.79), Color(red: 0.90, green: 0.83, blue: 0.67)]
        case .neon: [Color(red: 0.08, green: 0.08, blue: 0.13), Color(red: 0.03, green: 0.03, blue: 0.06)]
        case .classic, .fourColor, .largePrint: [Color(white: 1.0), Color(red: 0.965, green: 0.955, blue: 0.93)]
        }
    }

    var isDark: Bool { self == .night || self == .neon }

    /// The hairline around a face: a lit top edge fading into shade.
    var edge: [Color] {
        isDark ? [Color.white.opacity(0.38), Color.white.opacity(0.10)] : [Color.white, Color.black.opacity(0.16)]
    }

    /// Corner index size relative to card width.
    var indexScale: CGFloat { self == .largePrint ? 1.22 : 1 }
}

struct CardStyle: Equatable {
    var back: CardBackTheme = .crimson
    var face: FaceTheme = .classic
}

/// A ready-made table, card back and face combination.
struct ThemePreset: Identifiable, Equatable {
    var name: String
    var table: TableTheme
    var back: CardBackTheme
    var face: FaceTheme

    var id: String { name }

    static let all: [ThemePreset] = [
        ThemePreset(name: "Classic", table: .green, back: .crimson, face: .classic),
        ThemePreset(name: "Midnight", table: .midnight, back: .midnight, face: .night),
        ThemePreset(name: "Vintage", table: .tan, back: .copper, face: .vintage),
        ThemePreset(name: "Lagoon", table: .lagoon, back: .ocean, face: .classic),
        ThemePreset(name: "Royal", table: .purple, back: .amethyst, face: .classic),
        ThemePreset(name: "Neon", table: .charcoal, back: .carbon, face: .neon),
        ThemePreset(name: "Sunset", table: .sunset, back: .sunburst, face: .classic),
        ThemePreset(name: "Aurora", table: .aurora, back: .sky, face: .fourColor),
        ThemePreset(name: "Rosewood", table: .rosewood, back: .rose, face: .vintage),
        ThemePreset(name: "Slate", table: .slate, back: .slate, face: .night),
    ]
}

private struct CardStyleKey: EnvironmentKey {
    static let defaultValue = CardStyle()
}

extension EnvironmentValues {
    var cardStyle: CardStyle {
        get { self[CardStyleKey.self] }
        set { self[CardStyleKey.self] = newValue }
    }
}

// MARK: - Settings screen

struct AppearanceView: View {
    @Binding var table: TableTheme
    @Binding var back: CardBackTheme
    @Binding var face: FaceTheme
    @Binding var leftHanded: Bool
    @Environment(\.dismiss) private var dismiss

    private let previewSize = CardSize(width: 58, height: 85, facePeek: 30, backPeek: 12, spacing: 4)
    private let facePreviewSize = CardSize(width: 44, height: 64, facePeek: 24, backPeek: 10, spacing: 4)
    private let presetCardSize = CardSize(width: 36, height: 52, facePeek: 20, backPeek: 8, spacing: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    section("Themes") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ThemePreset.all) { preset in
                                    Button {
                                        withAnimation(.snappy) {
                                            table = preset.table
                                            back = preset.back
                                            face = preset.face
                                        }
                                    } label: {
                                        presetTile(preset)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("\(preset.name) theme")
                                    .accessibilityAddTraits(isCurrent(preset) ? .isSelected : [])
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.horizontal, -20)
                    }

                    section("Table") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
                            ForEach(TableTheme.allCases) { theme in
                                Button { withAnimation(.snappy) { table = theme } } label: {
                                    VStack(spacing: 6) {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(LinearGradient(colors: theme.colors, startPoint: .top, endPoint: .bottom))
                                            .frame(height: 64)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .strokeBorder(table == theme ? Felt.gold : .white.opacity(0.15), lineWidth: table == theme ? 3 : 1)
                                            }
                                        Text(theme.name)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(Felt.cream)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    section("Card Back") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 78), spacing: 12)], spacing: 14) {
                            ForEach(CardBackTheme.allCases) { theme in
                                Button { withAnimation(.snappy) { back = theme } } label: {
                                    VStack(spacing: 6) {
                                        CardView(card: sample(.spades, .ace), size: previewSize, faceUp: false)
                                            .environment(\.cardStyle, CardStyle(back: theme, face: face))
                                            .padding(4)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: previewSize.corner + 4, style: .continuous)
                                                    .strokeBorder(back == theme ? Felt.gold : .clear, lineWidth: 3)
                                            }
                                        Text(theme.name)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(Felt.cream)
                                            .lineLimit(1)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    section("Card Faces") {
                        VStack(spacing: 10) {
                            ForEach(FaceTheme.allCases) { theme in
                                Button { withAnimation(.snappy) { face = theme } } label: {
                                    HStack(spacing: 14) {
                                        HStack(spacing: -18) {
                                            ForEach([Suit.spades, .hearts, .diamonds, .clubs], id: \.self) { suit in
                                                CardView(card: sample(suit, suit == .spades ? .king : .seven), size: facePreviewSize, faceUp: true)
                                            }
                                        }
                                        .environment(\.cardStyle, CardStyle(back: back, face: theme))
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(theme.name).font(.headline).foregroundStyle(Felt.cream)
                                            Text(theme.detail).font(.caption).foregroundStyle(Felt.cream.opacity(0.65))
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        Spacer(minLength: 0)
                                        Image(systemName: face == theme ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle(face == theme ? Felt.gold : Felt.cream.opacity(0.35))
                                    }
                                    .padding(12)
                                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    section("Layout") {
                        Toggle(isOn: $leftHanded) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Left-Handed Layout").foregroundStyle(Felt.cream)
                                Text("Puts the stock pile on the left.").font(.caption).foregroundStyle(Felt.cream.opacity(0.65))
                            }
                        }
                        .tint(Felt.gold)
                        .padding(12)
                        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(20)
            }
            .background(LinearGradient(colors: table.colors, startPoint: .top, endPoint: .bottom).ignoresSafeArea())
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(table.deep.opacity(0.9), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Felt.gold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(Felt.cream.opacity(0.6))
            content()
        }
    }

    private func isCurrent(_ preset: ThemePreset) -> Bool {
        table == preset.table && back == preset.back && face == preset.face
    }

    /// A miniature table with one card of each side, so a preset shows all three of its parts.
    private func presetTile(_ preset: ThemePreset) -> some View {
        let selected = isCurrent(preset)
        return VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: preset.table.colors, startPoint: .top, endPoint: .bottom))
                .frame(width: 104, height: 78)
                .overlay {
                    HStack(spacing: -10) {
                        CardView(card: sample(.spades, .ace), size: presetCardSize, faceUp: false)
                            .rotationEffect(.degrees(-7))
                        CardView(card: sample(.hearts, .queen), size: presetCardSize, faceUp: true)
                            .rotationEffect(.degrees(7))
                    }
                    .environment(\.cardStyle, CardStyle(back: preset.back, face: preset.face))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(selected ? Felt.gold : .white.opacity(0.15), lineWidth: selected ? 3 : 1)
                }
            Text(preset.name)
                .font(.caption.weight(.medium))
                .foregroundStyle(Felt.cream)
        }
    }

    private func sample(_ suit: Suit, _ rank: Rank) -> Card {
        Card(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000\(suit.rawValue)\(rank.rawValue % 10)") ?? UUID(), suit: suit, rank: rank, isFaceUp: true)
    }
}
