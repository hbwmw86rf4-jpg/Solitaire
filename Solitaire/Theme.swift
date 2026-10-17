import SwiftUI

enum TableTheme: String, CaseIterable, Identifiable {
    case green, blue, crimson, purple, charcoal, tan

    var id: String { rawValue }

    var name: String {
        switch self {
        case .green: "Classic Green"
        case .blue: "Ocean"
        case .crimson: "Casino Red"
        case .purple: "Velvet"
        case .charcoal: "Charcoal"
        case .tan: "Walnut"
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
        }
    }

    var deep: Color { colors[2] }
}

enum CardBackPattern {
    case lattice, stripes, dots, plain
}

enum CardBackTheme: String, CaseIterable, Identifiable {
    case crimson, navy, emerald, midnight, rose, ocean

    var id: String { rawValue }

    var name: String {
        switch self {
        case .crimson: "Crimson"
        case .navy: "Navy"
        case .emerald: "Emerald"
        case .midnight: "Midnight Gold"
        case .rose: "Rose"
        case .ocean: "Teal Stripe"
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
        }
    }

    var accent: Color {
        switch self {
        case .rose: Color(red: 1.0, green: 0.92, blue: 0.88)
        case .ocean: Color(red: 0.85, green: 0.97, blue: 0.95)
        default: Felt.gold
        }
    }

    var pattern: CardBackPattern {
        switch self {
        case .crimson, .navy: .lattice
        case .emerald, .rose: .dots
        case .ocean: .stripes
        case .midnight: .plain
        }
    }
}

enum FaceTheme: String, CaseIterable, Identifiable {
    case classic, fourColor, largePrint

    var id: String { rawValue }

    var name: String {
        switch self {
        case .classic: "Classic"
        case .fourColor: "Four-Color"
        case .largePrint: "Large Print"
        }
    }

    var detail: String {
        switch self {
        case .classic: "Red and black suits."
        case .fourColor: "Each suit has its own color."
        case .largePrint: "Bigger corner labels."
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
        default:
            suit.isRed ? Felt.red : Felt.ink
        }
    }

    /// Corner index size relative to card width.
    var indexScale: CGFloat { self == .largePrint ? 1.22 : 1 }
}

struct CardStyle: Equatable {
    var back: CardBackTheme = .crimson
    var face: FaceTheme = .classic
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
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

    private func sample(_ suit: Suit, _ rank: Rank) -> Card {
        Card(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000\(suit.rawValue)\(rank.rawValue % 10)") ?? UUID(), suit: suit, rank: rank, isFaceUp: true)
    }
}
