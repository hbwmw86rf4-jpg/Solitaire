import SwiftUI

enum Felt {
    static let green = Color(red: 0.08, green: 0.33, blue: 0.20)
    static let greenDeep = Color(red: 0.04, green: 0.18, blue: 0.11)
    static let gold = Color(red: 0.96, green: 0.82, blue: 0.42)
    static let cream = Color(red: 0.97, green: 0.94, blue: 0.86)
}

struct CardSize {
    var width: CGFloat
    var height: CGFloat
    var peek: CGFloat
    var spacing: CGFloat
    var corner: CGFloat { max(6, width * 0.11) }
}

struct CardView: View {
    let card: Card
    let size: CardSize
    var lifted = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.corner, style: .continuous)
                .fill(card.isFaceUp ? Color.white : Color.clear)
            if card.isFaceUp {
                face
            } else {
                cardBack
            }
            RoundedRectangle(cornerRadius: size.corner, style: .continuous)
                .strokeBorder(Color.black.opacity(0.16), lineWidth: 0.8)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: size.corner, style: .continuous))
        .shadow(
            color: .black.opacity(lifted ? 0.38 : 0.16),
            radius: lifted ? 12 : 2.5,
            y: lifted ? 8 : 1.5
        )
        .scaleEffect(lifted ? 1.04 : 1)
        .accessibilityLabel(card.accessibilityLabel)
    }

    private var face: some View {
        let ink: Color = card.suit.isRed
            ? Color(red: 0.78, green: 0.12, blue: 0.16)
            : Color(red: 0.10, green: 0.10, blue: 0.12)
        let rankFont = card.rank == .ten ? size.width * 0.22 : size.width * 0.28
        let pipFont = size.width * 0.18
        let centerFont = size.width * 0.42

        return ZStack {
            Text(card.suit.symbol)
                .font(.system(size: centerFont, weight: .medium))

            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    cornerIndex(rankFont: rankFont, pipFont: pipFont)
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
                HStack(alignment: .bottom, spacing: 0) {
                    Spacer(minLength: 0)
                    cornerIndex(rankFont: rankFont, pipFont: pipFont)
                }
            }
            .padding(.horizontal, 3)
            .padding(.vertical, 4)
        }
        .foregroundStyle(ink)
    }

    private func cornerIndex(rankFont: CGFloat, pipFont: CGFloat) -> some View {
        VStack(spacing: -2) {
            Text(card.rank.display)
                .font(.system(size: rankFont, weight: .bold, design: .serif).width(.condensed))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .allowsTightening(true)
            Text(card.suit.symbol)
                .font(.system(size: pipFont, weight: .semibold))
        }
        .frame(width: size.width * 0.40, alignment: .center)
    }

    private var cardBack: some View {
        RoundedRectangle(cornerRadius: size.corner, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.18, green: 0.22, blue: 0.52),
                        Color(red: 0.09, green: 0.11, blue: 0.32)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: max(3, size.corner - 3), style: .continuous)
                    .strokeBorder(Felt.gold.opacity(0.55), lineWidth: 1.6)
                    .padding(5)
            }
            .overlay {
                Image(systemName: "diamond.fill")
                    .font(.system(size: size.width * 0.34))
                    .foregroundStyle(Felt.gold.opacity(0.85))
            }
    }
}

struct EmptyPileView: View {
    let size: CardSize
    var symbol: String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.corner, style: .continuous)
                .fill(Color.black.opacity(0.12))
            RoundedRectangle(cornerRadius: size.corner, style: .continuous)
                .strokeBorder(Color.white.opacity(0.28), style: StrokeStyle(lineWidth: 1.4, dash: [6, 4]))
            if let symbol {
                Text(symbol)
                    .font(.system(size: size.width * 0.36, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.28))
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
