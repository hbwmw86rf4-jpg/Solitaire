import SwiftUI

enum Felt {
    static let green = Color(red: 0.07, green: 0.36, blue: 0.22)
    static let greenDeep = Color(red: 0.03, green: 0.17, blue: 0.10)
    static let gold = Color(red: 0.96, green: 0.82, blue: 0.42)
    static let cream = Color(red: 0.97, green: 0.94, blue: 0.86)
    static let red = Color(red: 0.80, green: 0.10, blue: 0.16)
    static let ink = Color(red: 0.09, green: 0.09, blue: 0.12)
    static let backTop = Color(red: 0.60, green: 0.09, blue: 0.16)
    static let backBottom = Color(red: 0.32, green: 0.03, blue: 0.08)
}

extension Animation {
    static let cardMove = Animation.spring(response: 0.36, dampingFraction: 0.82)
    static let cardSnap = Animation.spring(response: 0.30, dampingFraction: 0.68)
    static let cardDeal = Animation.spring(response: 0.42, dampingFraction: 0.80)
}

extension Suit {
    var sfSymbol: String {
        switch self {
        case .spades: "suit.spade.fill"
        case .hearts: "suit.heart.fill"
        case .diamonds: "suit.diamond.fill"
        case .clubs: "suit.club.fill"
        }
    }
}

struct CardSize: Equatable {
    var width: CGFloat
    var height: CGFloat
    var facePeek: CGFloat
    var backPeek: CGFloat
    var spacing: CGFloat
    var corner: CGFloat { max(7, width * 0.11) }
    var fanStep: CGFloat { width * 0.42 }

    func stackOffset(at index: Int, in cards: [Card]) -> CGFloat {
        guard index > 0, !cards.isEmpty else { return 0 }
        let end = min(index, cards.count)
        var y: CGFloat = 0
        for i in 0..<end {
            y += cards[i].isFaceUp ? facePeek : backPeek
        }
        return y
    }

    func stackHeight(for cards: [Card]) -> CGFloat {
        if cards.isEmpty { return height }
        return stackOffset(at: cards.count - 1, in: cards) + height
    }

    func exposedPeek(at index: Int, in cards: [Card]) -> CGFloat {
        guard cards.indices.contains(index) else { return facePeek }
        if index == cards.count - 1 { return height }
        return cards[index].isFaceUp ? facePeek : backPeek
    }
}

/// A card that flips in 3D when `faceUp` changes inside an animation.
struct CardView: View {
    let card: Card
    let size: CardSize
    var faceUp: Bool
    var lifted = false

    init(card: Card, size: CardSize, faceUp: Bool? = nil, lifted: Bool = false) {
        self.card = card
        self.size = size
        self.faceUp = faceUp ?? card.isFaceUp
        self.lifted = lifted
    }

    var body: some View {
        FlipContainer(angle: faceUp ? 0 : 180) {
            CardFace(suit: card.suit, rank: card.rank, size: size)
        } back: {
            CardBack(size: size)
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: .black.opacity(lifted ? 0.18 : 0.22), radius: lifted ? 2 : 0.6, y: lifted ? 2 : 0.6)
        .shadow(color: .black.opacity(lifted ? 0.38 : 0.10), radius: lifted ? 18 : 3, y: lifted ? 14 : 2)
        .scaleEffect(lifted ? 1.06 : 1)
        .accessibilityLabel(faceUp ? card.accessibilityLabel : "face down card")
    }
}

private struct FlipContainer<Front: View, Back: View>: View, Animatable {
    var angle: Double
    @ViewBuilder var front: Front
    @ViewBuilder var back: Back

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        ZStack {
            if angle < 90 {
                front
            } else {
                back.scaleEffect(x: -1, y: 1)
            }
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.45)
    }
}

private struct CardFace: View, Equatable {
    let suit: Suit
    let rank: Rank
    let size: CardSize

    private var ink: Color { suit.isRed ? Felt.red : Felt.ink }
    private var isCourt: Bool { rank == .jack || rank == .queen || rank == .king }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size.corner, style: .continuous)
        ZStack {
            shape.fill(
                LinearGradient(
                    colors: [Color(white: 1.0), Color(red: 0.965, green: 0.955, blue: 0.93)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            center
                .padding(.top, size.height * 0.30)
                .padding(.bottom, size.height * 0.10)
                .padding(.horizontal, size.width * 0.14)

            cornerIndex
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, size.width * 0.08)
                .padding(.top, size.width * 0.05)

            shape.strokeBorder(
                LinearGradient(
                    colors: [Color.white, Color.black.opacity(0.16)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 0.8
            )
        }
        .foregroundStyle(ink)
        .clipShape(shape)
        .compositingGroup()
    }

    private var cornerIndex: some View {
        HStack(alignment: .firstTextBaseline, spacing: size.width * 0.03) {
            Text(rank.display)
                .font(.system(size: size.width * (rank == .ten ? 0.30 : 0.34), weight: .bold, design: .rounded))
                .tracking(rank == .ten ? -1.2 : 0)
                .lineLimit(1)
                .fixedSize()
            Image(systemName: suit.sfSymbol)
                .font(.system(size: size.width * 0.22, weight: .bold))
        }
    }

    @ViewBuilder
    private var center: some View {
        if isCourt {
            let inset = RoundedRectangle(cornerRadius: size.corner * 0.6, style: .continuous)
            ZStack {
                inset.fill(
                    LinearGradient(
                        colors: [ink.opacity(0.10), ink.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                inset.strokeBorder(Felt.gold.opacity(0.9), lineWidth: max(1, size.width * 0.02))
                VStack(spacing: 0) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: size.width * 0.16))
                        .foregroundStyle(Felt.gold)
                        .shadow(color: .black.opacity(0.2), radius: 0.5, y: 0.5)
                    Text(rank.display)
                        .font(.system(size: size.width * 0.40, weight: .heavy, design: .serif))
                    Image(systemName: suit.sfSymbol)
                        .font(.system(size: size.width * 0.16))
                }
                .minimumScaleFactor(0.4)
            }
        } else {
            Image(systemName: suit.sfSymbol)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: size.width * (rank == .ace ? 0.56 : 0.46))
                .shadow(color: ink.opacity(0.25), radius: 1, y: 1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct CardBack: View, Equatable {
    let size: CardSize

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size.corner, style: .continuous)
        let innerCorner = max(3, size.corner - 4)
        let inset = max(3.5, size.width * 0.07)
        ZStack {
            shape.fill(Color(white: 0.98))
            RoundedRectangle(cornerRadius: innerCorner, style: .continuous)
                .fill(
                    LinearGradient(colors: [Felt.backTop, Felt.backBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay {
                    LatticePattern(spacing: max(5, size.width * 0.11))
                        .stroke(Color.white.opacity(0.13), lineWidth: 0.8)
                        .clipShape(RoundedRectangle(cornerRadius: innerCorner, style: .continuous))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: max(2, innerCorner - 2), style: .continuous)
                        .strokeBorder(Felt.gold.opacity(0.75), lineWidth: max(0.8, size.width * 0.014))
                        .padding(max(2, size.width * 0.045))
                }
                .overlay {
                    ZStack {
                        Circle()
                            .fill(Felt.backBottom)
                            .overlay(Circle().strokeBorder(Felt.gold.opacity(0.85), lineWidth: max(0.8, size.width * 0.015)))
                        Image(systemName: "suit.spade.fill")
                            .font(.system(size: size.width * 0.18))
                            .foregroundStyle(Felt.gold)
                    }
                    .frame(width: size.width * 0.38, height: size.width * 0.38)
                }
                .overlay {
                    LinearGradient(
                        colors: [.white.opacity(0.16), .clear, .black.opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: innerCorner, style: .continuous))
                }
                .padding(inset)
            shape.strokeBorder(Color.black.opacity(0.18), lineWidth: 0.6)
        }
        .clipShape(shape)
        .compositingGroup()
    }
}

private struct LatticePattern: Shape {
    var spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let span = rect.width + rect.height
        var d: CGFloat = -rect.height
        while d < span {
            path.move(to: CGPoint(x: rect.minX + d, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + d + rect.height, y: rect.maxY))
            path.move(to: CGPoint(x: rect.minX + d + rect.height, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + d, y: rect.maxY))
            d += spacing
        }
        return path
    }
}

struct EmptyPileView: View {
    let size: CardSize
    var symbol: String?
    var systemImage: String?

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size.corner, style: .continuous)
        ZStack {
            shape.fill(Color.black.opacity(0.16))
            shape.strokeBorder(Color.white.opacity(0.20), lineWidth: 1.2)
            shape.strokeBorder(Color.black.opacity(0.18), lineWidth: 3).blur(radius: 2).clipShape(shape)
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: size.width * 0.32, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.30))
            } else if let symbol {
                Text(symbol)
                    .font(.system(size: size.width * 0.40, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.white.opacity(0.22))
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
